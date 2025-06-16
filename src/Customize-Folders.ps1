<#
.SYNOPSIS
	Customizes folders by copying icons and updating desktop.ini files based on a JSON configuration.
.DESCRIPTION
	This script reads a JSON file containing folder definitions. For each folder, it optionally copies an icon file to the folder, sets file attributes, and creates or updates the desktop.ini file with the specified configuration. Environment variables in paths are expanded. Supports a WhatIf mode to preview actions.
.PARAMETER JsonPath
	Path to the JSON configuration file. Default is ".\folders.json".
.PARAMETER IconsPath
	Path to the folder containing icon files. Default is "..\ico\".
.PARAMETER WhatIf
	If specified, shows what actions would be performed without making any changes.
.EXAMPLE
	.\Customize-Folders.ps1 -JsonPath .\folders.json -IconsPath ..\ico\

	Reads a JSON file, stored at .\folders.json, containing folder definitions and customizes the folders accordingly.
.EXAMPLE
	.\Customize-Folders.ps1 -JsonPath .\folders.json -IconsPath ..\ico\ -WhatIf

	Reads a JSON file, stored at .\folders.json, containing folder definitions and shows the actions that would be taken without making any changes.
.NOTES
	The script expects the JSON to have a "folders" array, formatted by the schema at https://github.com/lperezperez/Windows11Icons/blob/master/src/schema.json.
#>
param(
	[string]$JsonPath = ".\folders.json",
	[string]$IconsPath = "..\ico\",
	[switch]$WhatIf
)
$json = Get-Content $JsonPath -Raw | ConvertFrom-Json
foreach ($folder in $json.folders) {
	if ($WhatIf) { Write-Host "" }
	$folderPath = [Environment]::ExpandEnvironmentVariables($folder.Path)
	if (-not $folderPath) {
		Write-Host "Folder $($folderPath) don't have a path."
		continue
	}
	if (-not (Test-Path $folderPath)) {
		Write-Host "The specified path for folder $($folderPath) does not exist: $($folderPath)."
		continue
	}
	if ($folder.IconFile) {
		$iconSrc = Join-Path $IconsPath $folder.IconFile
		if (Test-Path $iconSrc) {
			$iconDst = Join-Path $folderPath "Folder.ico"
			if ($WhatIf) {
				Write-Host "[WhatIf] Copy $iconSrc to $iconDst and mark it as hidden."
			}
			else {
				Copy-Item $iconSrc $iconDst -Force
				Attrib +H $iconDst
			}
		}
		elseif ($WhatIf) {
			Write-Host "[WhatIf] Cannot find $iconSrc"
		}
	}
	if ($folder.DesktopIni) {
		$iniPath = Join-Path $folderPath "desktop.ini"
		$ini = @{}
		if (Test-Path $iniPath) {
			$section = $null
			foreach ($line in Get-Content $iniPath) {
				if ($line -match "^\[(.+)\]$") {
					$section = $matches[1];
					$ini[$section] = @{}
				}
				elseif ($line -match "^([^=]+)=(.*)$" -and $section) { $ini[$section][$matches[1].Trim()] = $matches[2].Trim() }
			}
		}
		foreach ($section in ($folder.DesktopIni.PSObject.Properties.Name | Sort-Object)) {
			$props = $folder.DesktopIni.$section | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Sort-Object
			if (-not $ini.ContainsKey($section)) { $ini[$section] = @{} }
			foreach ($prop in $props) { $ini[$section][$prop] = $folder.DesktopIni.$section.$prop }
		}
		$out = @()
		foreach ($section in ($ini.Keys | Sort-Object)) {
			$out += "[$section]"
			foreach ($prop in ($ini[$section].Keys | Sort-Object)) { $out += "$prop=$($ini[$section][$prop])" }
		}
		$outStr = $out -join "`n"
		if ($WhatIf) {
			Write-Host "[WhatIf] Set $($iniPath) as hidden and system file. Content:`n$outStr"
		}
		else {
			$out | Set-Content $iniPath -Encoding UTF8
			Attrib +H +S $iniPath
		}
	}
}
# Rebuid icon cache
if ($WhatIf) {
	Write-Host "`n[WhatIf] Icon cache rebuild would be triggered."
}
else {
	$iconCacheDbPath = Join-Path $env:LocalAppData "IconCache.db"
	$iconCachePath = Join-Path $env:LocalAppData "Microsoft\Windows\Explorer\iconcache*"
	if ((Test-Path $iconCacheDbPath) -or (Test-Path $iconCachePath)) {
		Write-Host "`nRebuilding icon cache..."
		Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
		Remove-Item $iconCacheDbPath -Force -ErrorAction SilentlyContinue
		Remove-Item $iconCachePath -Force -ErrorAction SilentlyContinue
		Start-Process explorer.exe
	}
	else {
		Write-Host "`nIcon cache not found"
	}
}