param ([string]$SvgFolder = ".\svg", [string]$IcoFolder = ".\ico", $Density = 300)

# Calculates the SHA1 hash of a given file
# 
# Parameters:
#   $filePath - The full path to the file to hash
#
# Returns:
#   String containing the SHA1 hash of the file
function Get-FileHashSHA1($filePath) {
	return (Get-FileHash -Path $filePath -Algorithm SHA1).Hash
}
function Convert-SgvToIco {
	param ($bigSvg, $smallSvg, $ico)
	$magickArgs = @()
	foreach ($size in @(256, 64, 48, 40, 32, 24, 20, 16)) {
		# Creates a new image processing group.
		$magickArgs += "("
		$magickArgs += "-density"
		$magickArgs += $Density
		$magickArgs += "-background"
		$magickArgs += "none"
		$magickArgs += (($size -lt 40) ? $smallSvg : $bigSvg)
		$magickArgs += "-resize"
		$magickArgs += "${size}x${size}"
		# Optional: if the SVG input image is not square, center it.
		$magickArgs += "-gravity"
		$magickArgs += "center"
		# Optional: Ensures the output is square.
		$magickArgs += "-extent"
		$magickArgs += "${size}x${size}"
		$magickArgs += ")"
	}
	$magickArgs += $ico # ICO output file
	try {
		& magick @magickArgs
		if ($LASTEXITCODE -ne 0) {
			Write-Error "❌ ImageMagick failed with exit code: $LASTEXITCODE"
			throw "ImageMagick execution failed."
		}
		return $true
	} catch {
		Write-Error "❌ An error occurred while executing ImageMagick: $($_.Exception.Message)"
		return $false
	}
}
# Create output folder if it doesn't exist
if (-not (Test-Path $IcoFolder)) {
	New-Item -ItemType Directory -Path $IcoFolder | Out-Null
}
# Set C:\Program Files\WindowsApps\ImageMagick.Q16_7.1.1.47_x64__b3hnabsze9y3j
$Env:MAGICK_CONFIGURE_PATH = "C:\Program Files\WindowsApps\ImageMagick.Q16_7.1.1.47_x64__b3hnabsze9y3j"
# Process each pair of SVGs
Get-ChildItem -Path $SvgFolder -Filter *-big.svg | ForEach-Object {
	[string]$bigSvg = $_.FullName
	[string]$name = $_.BaseName -replace '-big$', ''
	[string]$smallSvg = Join-Path $SvgFolder "$name-small.svg"
	[string]$ico = Join-Path $IcoFolder "$name.ico"
	[string]$hash = Join-Path $IcoFolder "$name.hash"
	if (-not (Test-Path $smallSvg)) {
		$smallSvg = $bigSvg
	}
	$currentHash = "$(Get-FileHashSHA1 $bigSvg)$(Get-FileHashSHA1 $smallSvg)"
	if (Test-Path $hash) {
		if ($(Get-Content $hash) -eq $currentHash -and (Test-Path $ico)) {
			Write-Host "👌 $name"
			return
		}
	}
	if ((Convert-SgvToIco $bigSvg $smallSvg $ico)) {
		# $currentHash | Out-File -Encoding ascii -NoNewline $hash
		Write-Host "➕ $name"
	}
}