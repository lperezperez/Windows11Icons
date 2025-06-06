<#
.SYNOPSIS
	Script to create Windows 11 icons from SVG files.
.DESCRIPTION
	This script processes SVG files from a specified folder and generates icon files (.ico) in the output folder.
	It uses ImageMagick to convert SVG files into ICO format, creating icons of various sizes suitable for Windows 11.
	For each pair of SVG files (big and small), it checks if the output icon already exists and is up-to-date based on the SHA1 hash of the SVG files. Generates the diferent icon sizes (256, 64, 48 and 40, for the big SVG and 32, 24, 20, and 16 pixels, for the small SVG) by resizing the SVG files. The script assumes that the big SVG file is named with a "-big" suffix and the small SVG file with a "-small" suffix. If the small SVG file does not exist, it uses the big SVG file for all sizes.
.PARAMETER SvgFolder
	The path to the folder containing SVG files. Defaults to "Create-IconsFromSvg.ps1\..\svg".
.PARAMETER IcoFolder
	The path to the folder where generated ICO files will be saved. Defaults to "Create-IconsFromSvg.ps1\..\ico".
.PARAMETER Density
	The density (in DPI) used for rendering the icons. Defaults to 300.
.EXAMPLE
	.\Create-IconsFromSvg.ps1 -SvgFolder "C:\path\to\svg" -IcoFolder "C:\path\to\ico" -Density 300
	This command processes SVG files in the specified folder and generates icons in the output folder with a density of 300 DPI.
#>
[CmdletBinding()]
param ([string]$SvgFolder = (Resolve-Path(Join-Path $PSScriptRoot ..\svg)).Path, [string]$IcoFolder = (Resolve-Path(Join-Path $PSScriptRoot ..\ico)).Path, $Density = 300)
function Get-FileHashSHA1 {
	<#
	.SYNOPSIS
		Calculates the SHA1 hash of a file.
	.PARAMETER filePath
		The full path to the file to hash.
	.OUTPUTS
		String containing the SHA1 hash of the file.
	#>
	param ([string]$filePath)
	return (Get-FileHash -Path $filePath -Algorithm SHA1).Hash
}
function Convert-SgvToIco {
	<#
	.SYNOPSIS
		Converts SVG files to a multi-resolution ICO file using ImageMagick.
	.DESCRIPTION
		Generates a Windows icon (.ico) file containing multiple sizes from two SVG sources (big and small).
		Uses the big SVG for sizes 40px and above, and the small SVG for sizes below 40px.
		Ensures each icon size is centered and squared. Handles errors from ImageMagick execution.
	.PARAMETER bigSvg
		Path to the SVG file used for larger icon sizes (>= 40px).
	.PARAMETER smallSvg
		Path to the SVG file used for smaller icon sizes (< 40px).
	.PARAMETER ico
		Output path for the generated ICO file.
	.OUTPUTS
		[bool] True if the conversion was successful, otherwise False.
	.EXAMPLE
		Convert-SgvToIco -bigSvg "icon-big.svg" -smallSvg "icon-small.svg" -ico "icon.ico"
	#>
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
		Write-Verbose "Executing: magick $magickArgs"
		# Write-Verbose "Executing: magick $($magickArgs -join ' ')"
		& magick @magickArgs
		if ($LASTEXITCODE -ne 0) {
			Write-Error "🚫 ImageMagick failed with exit code: $LASTEXITCODE"
			throw "ImageMagick execution failed."
		}
		return $true
	} catch {
		Write-Error "🚫 An error occurred while executing ImageMagick: $($_.Exception.Message)"
		return $false
	}
}
function Set-MagickConfigurePath {
	<#
	.SYNOPSIS
		Sets the MAGICK_CONFIGURE_PATH.
	.DESCRIPTION
		Sets the MAGICK_CONFIGURE_PATH environment variable.
	#>
	param ()
	$env:MAGICK_CONFIGURE_PATH = &(Join-Path $PSScriptRoot .\Resolve-TruePath.ps1) magick | Split-Path -Parent
	Write-Verbose "MAGICK_CONFIGURE_PATH set to: $env:MAGICK_CONFIGURE_PATH"
}
Write-Verbose "Path to SVG folder: $SvgFolder"
Write-Verbose "Path to ICO folder: $IcoFolder"
Write-Verbose "Density: $Density DPI"
# Ensure the SVG folder exists
if (-not (Test-Path $SvgFolder)) {
	Write-Error "🚫 SVG folder not found: $SvgFolder"
	exit
}
# Create output folder if it doesn't exist
if (-not (Test-Path $IcoFolder)) {
	Write-Verbose "Creating ICO folder: $IcoFolder"
	New-Item -ItemType Directory -Path $IcoFolder | Out-Null
}
# Check MAGICK_CONFIGURE_PATH environment variable
if ($Env:MAGICK_CONFIGURE_PATH) {
	Write-Verbose "MAGICK_CONFIGURE_PATH is set to: $Env:MAGICK_CONFIGURE_PATH"
	if (-not (Test-Path $Env:MAGICK_CONFIGURE_PATH) -or -not (Test-Path (Join-Path $Env:MAGICK_CONFIGURE_PATH "magick.exe")) -or ($magick.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
		Set-MagickConfigurePath
	}
}
# Set MAGICK_CONFIGURE_PATH environment variable if not already set
elseif (-not $Env:MAGICK_CONFIGURE_PATH) {
	Write-Verbose "MAGICK_CONFIGURE_PATH is not set. Setting it now."
	Set-MagickConfigurePath
}
# Process each pair of SVGs
Get-ChildItem -Path $SvgFolder -Filter *-big.svg | ForEach-Object {
	$bigSvg = $_.FullName
	$name = $_.BaseName -replace "-big$", ""
	Write-Verbose "Checking SVG: $name"
	Write-Verbose "Big SVG: $bigSvg"
	$smallSvg = Join-Path $SvgFolder "$name-small.svg"
	if (-not (Test-Path $smallSvg)) {
		$smallSvg = $bigSvg
	}
	else {
		Write-Verbose "Small SVG: $smallSvg"
	}
	$ico = Join-Path $IcoFolder "$name.ico"
	$hash = Join-Path $IcoFolder "$name.hash"
	$currentHash = "$(Get-FileHashSHA1 $bigSvg)$(Get-FileHashSHA1 $smallSvg)"
	if (Test-Path $hash) {
		Write-Verbose "Checking if icon is up-to-date: $ico"
		if ($(Get-Content $hash) -eq $currentHash -and (Test-Path $ico)) {
			Write-Host "⏭️  $name"
			return
		}
	}
	if ((Convert-SgvToIco $bigSvg $smallSvg $ico)) {
		$currentHash | Out-File -Encoding ascii -NoNewline $hash
		Write-Host "🔄️ $name"
	}
}