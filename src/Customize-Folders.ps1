param(
	[string]$JsonPath = ".\folders.json",
	[string]$IconsPath = "..\ico\",
	[switch]$WhatIf
)
$json = Get-Content $JsonPath -Raw | ConvertFrom-Json
foreach ($folder in $json.folders) {
	Write-Host ""
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