<#
.SYNOPSIS
	Script to create Windows 11 icons from SVG files.
.DESCRIPTION
	This script processes SVG files from a specified folder and generates icon files (.ico) in the output folder.
	It uses ImageMagick to convert SVG files into ICO format, creating icons of various sizes suitable for Windows 11.
	For each pair of SVG files (big and small), it checks if the output icon already exists and is up-to-date based on the SHA1 hash of the SVG files. Generates the diferent icon sizes (256, 64, 48 and 40, for the big SVG and 32, 24, 20, and 16 pixels, for the small SVG) by resizing the SVG files. The script assumes that the big SVG file is named with a "-big" suffix and the small SVG file with a "-small" suffix. If the small SVG file does not exist, it uses the big SVG file for all sizes.
.PARAMETER SvgFolder
	The path to the folder containing SVG files. Defaults to "..\svg".
.PARAMETER IcoFolder
	The path to the folder where generated ICO files will be saved. Defaults to "..\ico".
.PARAMETER Density
	The density (in DPI) used for rendering the icons. Defaults to 300.
.EXAMPLE
	.\Create-IconsFromSvg.ps1 -SvgFolder "C:\path\to\svg" -IcoFolder "C:\path\to\ico" -Density 300
	This command processes SVG files in the specified folder and generates icons in the output folder with a density of 300 DPI.
#>
param ([string]$SvgFolder = "..\svg", [string]$IcoFolder = "..\ico", $Density = 300)
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
# Set MAGICK_CONFIGURE_PATH if not already set
if (-not $Env:MAGICK_CONFIGURE_PATH) {
	$magickPath = Split-Path (.\Resolve-TruePath.ps1 magick)
	$Env:MAGICK_CONFIGURE_PATH = Split-Path $magickPath
}
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