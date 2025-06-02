<#
.SYNOPSIS
Resolves the absolute, canonical path of a given file or directory.
.DESCRIPTION
The Resolve-TruePath function takes a file or directory path as input and returns its fully qualified, resolved path. This includes resolving any symbolic links, relative path components, or environment variables to provide the true physical path on the filesystem.
.PARAMETER <CommandName>
Specifies the command to resolve.
.PARAMETER MaxResolutions optional
Specifies the maximum number of resolutions to attempt. This is useful to prevent infinite loops in case of circular links or unresolved paths. Default is 10.
.EXAMPLE
PS C:\> Resolve-TruePath -CommandName notepad
C:\windows\system32\notepad.exe
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string]$CommandName,
	[Parameter()]
	[int]$MaxResolutions = 10 # To avoid infinite loops, default to 10
)
function Get-ReparsePointTargetFromFsutil {
	[CmdletBinding()]
	param([Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][string]$Path)
	process {
		try {
			# Execute fsutil. Elevation is needed for some reparse points, but not usually for AppExecAlias.
			$fsutilOutput = fsutil reparsepoint query $Path
			if ($LASTEXITCODE -ne 0) {
				Write-Error "fsutil.exe failed with code $LASTEXITCODE. Output: $($fsutilOutput -join "`n")"
				return $null
			}
			# Extract hexadecimal bytes from the "Reparse Data" section
			$hexDataLines = [System.Collections.Generic.List[string]]::new()
			$inDataSection = $false
			foreach ($line in $fsutilOutput) {
				if ($line -match '^(Datos de análisis|Reparse Data):') {
					$inDataSection = $true
					continue
				}
				if ($inDataSection) {
					# Validate that the line looks like a line of hexadecimal data
					if ($line -match '^\s*[0-9a-fA-F]{4}:\s+(([0-9a-fA-F]{2}\s*){1,16})') {
						try {
							# Take only the hexadecimal part (e.g., 03 00 00 00 49 00 6d 00  61 00 67 00 65 00 4d 00)
							# Group 1 captures the part with the bytes and spaces.
							$hexBytesOnLine = $Matches[1].Trim() -replace '\s+', '' # Remove all spaces
							$hexDataLines.Add($hexBytesOnLine)
						}
						catch {
							Write-Warning "Error processing line '$line': $($_.Exception.Message)"
						}
					}
					else {
						# If the line is no longer a hexadecimal dump, exit the data section
						$inDataSection = $false
					}
				}
			}
			if ($hexDataLines.Count -eq 0) {
				Write-Error "No reparse data found in fsutil output."
				return $null
			}
			$allHex = $hexDataLines -join ''
			$byteArray = [byte[]]::new($allHex.Length / 2)
			for ($i = 0; $i -lt $allHex.Length; $i += 2) {
				$byteArray[$i / 2] = [System.Convert]::ToByte($allHex.Substring($i, 2), 16)
			}
			# Decode as UTF-16LE (Unicode in .NET)
			# AppExecLink data contains several null-terminated strings.
			# The structure is something like:
			# 1. Package ID
			# 2. App User Model ID (Entry Point)
			# 3. Target Executable Path (¡lo que queremos!)
			# 4. Application Working Directory (optional)
			# Remove the first 4 bytes which are the "Version" field:
			# 0xA000001B for the tag IO_REPARSE_TAG_APPEXECLINK
			# 0x8000001B for the tag NONAME_REPARSE_TAG_APPEXECLINK
			# For the tag 0x8000001B, the reparse data is usually:
			# ULONG StringCount;
			# USHORT StringLength[StringCount];
			# WCHAR StringData[];
			# However, `fsutil` already presents the content of `StringData` in a more direct way.
			# Parse the `StringData`.
			$decodedString = [System.Text.Encoding]::Unicode.GetString($byteArray)
			# Split by null character to get individual strings
			$strings = $decodedString.Split([char]0) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
			# For AppExecLinks (Tag 0x8000001B or 0xA000001B), the full path of the executable
			# is usually the third string in the list (index 2), or the last one that looks like an absolute path.
			$targetPath = $null
			if ($strings.Count -ge 3) {
				# Heuristic: the absolute path is usually the longest, contains ":\" and ends with a known file extension.
				$potentialPaths = @($strings | Where-Object { $_ -match '^[a-zA-Z]:\\.*\\.+\.\w{2,4}$' } | Sort-Object -Property Length -Descending)
				if ($potentialPaths.Count -gt 0) {
					# Sometimes there are multiple paths, the one we are looking for is usually the last one in the original structure or the most specific one. For AppExecLink, it is usually the third string.
					# Try the third one if it is a valid path, otherwise the longest one.
					if ($strings[2] -match '^[a-zA-Z]:\\') {
						$targetPath = $strings[2]
					}
					else {
						$targetPath = $potentialPaths[0] # La más larga que parece ruta
					}
				}
				# If it was not found by heuristics, and there are at least 3 strings, we try the third one directly.
				if (-not $targetPath -and $strings[2]) {
					if ($strings[2] -match '^[a-zA-Z]:\\') {
						$targetPath = $strings[2] # Double check
					}
				}
			}
			if (-not $targetPath -and $strings.Count -gt 0) {
				# As a last resort, if it could not be determined by index or strong pattern,
				# look for the last string that looks like a path.
				$lastPotentialPath = $strings | Where-Object { $_ -match '^[a-zA-Z]:\\' } | Select-Object -Last 1
				if ($lastPotentialPath) {
					$targetPath = $lastPotentialPath
				}
			}
			if ($targetPath) {
				return $targetPath.Trim()
			}
			else {
				Write-Warning "No se pudo determinar la ruta de destino para '$($Path.ProviderPath)' desde los datos de fsutil."
				Write-Host "Cadenas decodificadas:"
				$strings | ForEach-Object { Write-Host "- '$_'" }
				return $null
			}
		}
		catch {
			Write-Error "Error al procesar '$($Path.ProviderPath)': $($_.Exception.Message)"
			return $null
		}
	}
}
try {
	$initialPath = (Get-Command $CommandName -ErrorAction Stop).Source
}
catch {
	Write-Error "Command '$CommandName' not found or does not have an accessible 'Source' property."
	return $null
}
$currentPath = $initialPath
$resolvedPath = $null
$resolutionCount = 0
Write-Verbose "Resolving '$CommandName' from initial path: '$currentPath'"
while ($resolutionCount -lt $MaxResolutions) {
	$resolutionCount++
	$item = Get-Item -LiteralPath $currentPath -ErrorAction SilentlyContinue
	if (-not $item) {
		Write-Warning "Path '$currentPath' does not exist or is not accessible. Stopping resolution."
		return $resolvedPath # Return the last known valid path
	}
	$isReparsePoint = ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
	$isLnkFile = $item.Extension -eq ".lnk"
	$previousPath = $currentPath # Save for comparison
	if ($isLnkFile) {
		Write-Verbose "($resolutionCount) '$currentPath' is a .lnk file. Attempting to resolve with WScript.Shell."
		try {
			$shell = New-Object -ComObject WScript.Shell
			$shortcut = $shell.CreateShortcut($currentPath)
			$targetInLnk = $shortcut.TargetPath
			if (-not [string]::IsNullOrWhiteSpace($targetInLnk)) {
				# If TargetPath is relative, make it absolute based on the directory of the .lnk
				if (-not (Test-Path -LiteralPath $targetInLnk -PathType Container) -and -not (Test-Path -LiteralPath $targetInLnk -PathType Leaf) -and $targetInLnk -notmatch '^[a-zA-Z]:\\') {
					Write-Verbose "Target in .lnk ('$targetInLnk') is relative. Resolving against the directory of the .lnk: '$(Split-Path $currentPath)'"
					$targetInLnk = Join-Path (Split-Path $currentPath) $targetInLnk
					$targetInLnk = (Resolve-Path -LiteralPath $targetInLnk -ErrorAction SilentlyContinue).ProviderPath
				}
				if ($targetInLnk) {
					$currentPath = $targetInLnk
					Write-Verbose "($resolutionCount) LNK resolved to: '$currentPath'"
				}
				else {
					Write-Warning "($resolutionCount) Target of LNK '$previousPath' is empty or could not be resolved."
					$resolvedPath = $previousPath
					break # No further resolution possible
				}
			}
			else {
				Write-Warning "($resolutionCount) Target of LNK '$previousPath' is empty."
				$resolvedPath = $previousPath
				break # No further resolution possible
			}
		}
		catch {
			Write-Warning "($resolutionCount) Error resolving LNK '$previousPath': $($_.Exception.Message)"
			$resolvedPath = $previousPath
			break # Error resolving
		}
	}
	elseif ($isReparsePoint) {
		Write-Verbose "($resolutionCount) '$currentPath' is a Reparse Point."
		$targetProperty = $null
		try {
			# Get-Item.Target works for Symlinks and Junctions
			$targetProperty = (Get-Item -LiteralPath $currentPath -Force -ErrorAction SilentlyContinue).Target # -Force is important for some cases
		}
		catch {
			Write-Verbose "($resolutionCount) Error accessing Target property for '$currentPath': $($_.Exception.Message)"
		}
		if (-not [string]::IsNullOrWhiteSpace($targetProperty)) {
			# PowerShell 5.1 sometimes returns the original path if it can't resolve it.
			# Also, for symlinks to directories, Target may not be the final absolute path.
			# We need to ensure it's a *different* path or that we can resolve it further.
			$resolvedTarget = $null
			try {
				# Attempt to resolve it to ensure it's a complete and valid path
				# If it's a symbolic directory, Get-Item resolves it to itself, we need Resolve-Path
				$resolvedTargetCandidate = Resolve-Path -LiteralPath $targetProperty -ErrorAction SilentlyContinue
				if ($resolvedTargetCandidate) {
					$resolvedTarget = $resolvedTargetCandidate.ProviderPath
				}
				else {
					# If targetProperty is not a valid path by itself, try to join it to the directory of the symlink
					Write-Verbose "($resolutionCount) Target ('$targetProperty') is not a valid path by itself. Attempting to resolve relative to '$(Split-Path $currentPath)'"
					$tempPath = Join-Path (Split-Path $currentPath) $targetProperty
					$resolvedTargetCandidate = Resolve-Path -LiteralPath $tempPath -ErrorAction SilentlyContinue
					if ($resolvedTargetCandidate) {
						$resolvedTarget = $resolvedTargetCandidate.ProviderPath
					}
				}
			}
			catch { Write-Warning "Could not resolve '$targetProperty' as a path." }
			if ($resolvedTarget -and $resolvedTarget -ne $currentPath) {
				$currentPath = $resolvedTarget
				Write-Verbose "($resolutionCount) Reparse Point (via Target) resolved to: '$currentPath'"
			}
			else {
				# Here is where Get-Item.Target fails for AppExecLinks in PS 5.1
				Write-Verbose "($resolutionCount) (Get-Item).Target did not resolve '$previousPath' to a different or valid path (Target: '$targetProperty', ResolvedTarget: '$resolvedTarget'). It could be an AppExecLink not natively handled in PS 5.1 or the end of the chain."
				# At this point, if this were PS7+, $item.LinkType could help.
				# If it's PS5.1 and we suspect AppExecLink, you could:
				# 1. Return the $previousPath (current behavior if no further logic is added).
				# 2. Try parsing fsutil as a last resort (if you're willing to reintroduce it).
				# 3. Use P/Invoke (more complex).
				# Heuristic check for common AppExecLinks
				if ($previousPath -like "*\WindowsApps\*") {
					Write-Warning "$($resolutionCount): '$previousPath' seems to be a WindowsApps AppExecLink. Native resolution in PowerShell 5.1 may be limited. Returning this path."
				}
				$resolvedPath = $previousPath # No se pudo resolver más con métodos nativos de PS5.1
				break
			}
		}
		else {
			Write-Verbose "$($resolutionCount): Target property for Reparse Point '$previousPath' is empty. Trying to resolve with fsutil."
			$resolvedPath = Get-ReparsePointTargetFromFsutil -Path $currentPath
			break
		}
	}
	else {
		# Not a .lnk or Reparse Point, assume it's the final file
		Write-Verbose "$($resolutionCount): '$currentPath' is not a .lnk or Reparse Point. Considered final path."
		$resolvedPath = $currentPath
		break
	}
	# Check if the path actually changed to avoid loops if a link points to itself
	if ($currentPath -eq $previousPath) {
		Write-Verbose "$($resolutionCount): Path did not change ('$currentPath'). Stopping resolution to avoid loop."
		$resolvedPath = $currentPath
		break
	}
	$resolvedPath = $currentPath # Update the last successfully resolved path
}
if ($resolutionCount -ge $MaxResolutions) {
	Write-Warning "Maximum of $MaxResolutions resolutions reached. Returning last obtained path: '$resolvedPath'"
}
if (Test-Path -Path $resolvedPath -ErrorAction SilentlyContinue) {
	Write-Verbose "Resolved path for '$CommandName': '$resolvedPath'"
	return $resolvedPath
}
Write-Warning "The resolved path does not exist: '$resolvedPath'"