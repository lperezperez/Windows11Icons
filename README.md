![Banner.svg](Banner.svg "Windows 11 Icons")
[![Latest version: 1.3.0](https://img.shields.io/badge/version-1.3.0-0078d4.svg?label=Version&logo=V&logoColor=fff)](https://github.com/lperezperez/windows11icons/releases/tag/1.3.0) [![Platform: Windows](https://img.shields.io/badge/platform-Windows-0078d4.svg?logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDguNzQ1IiBoZWlnaHQ9IjQ4Ljc0NiIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMCAwdjIzLjEwNWgyMy4xMDVWMHptMjUuNjQgMHYyMy4xMDVoMjMuMTA1VjB6TTAgMjUuNjQydjIzLjEwNWgyMy4xMDVWMjUuNjQyem0yNS42NCAwdjIzLjEwNWgyMy4xMDVWMjUuNjQyeiIgZmlsbD0iIzAwNzhkNCIvPjwvc3ZnPg==&longCache=true "Microsoft Windows")](https://www.microsoft.com/windows)
> **PowerShell script** to convert _SVG images (`.svg`)_ into _multi-resolution icons (`.ico`)_ using **ImageMagick**.

**Table of Contents**
- [Legal Notice](#legal-notice)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
	- [Optional parameters](#optional-parameters)
		- [Example:](#example)
	- [How it works](#how-it-works)
	- [Notes](#notes)
	- [`Customize-Folders.ps1`](#customize-foldersps1)
		- [Usage](#usage-1)
		- [Optional parameters](#optional-parameters-1)
		- [Example:](#example-1)
- [Changelog](#changelog)
- [Maintainer](#maintainer)
- [Contribute](#contribute)
- [License](#license)

## Legal Notice
> **This repository provides icons in `SVG` format. Be sure to read the terms of use before using them.**
>
> The icons provided in this repository may include _trademarks_, _registered trademarks_, or _branded logos_. Their use is permitted **solely for personal purposes**. Any other use, including but not limited to commercial applications, redistribution, or modification, **requires explicit permission** from the copyright holder of the respective trademark or logo.
>
> This repository is not affiliated with **Microsoft** or any of its subsidiaries.
## Requirements
- [**PowerShell** (v5+)](https://github.com/PowerShell/powershell/releases)
- [**ImageMagick**](https://imagemagick.org/script/download.php) installed and `magick` available in `PATH`
- SVG files in `src/svg/`
## Installation
1. Install [ImageMagick](https://imagemagick.org/script/download.php) and ensure `magick` is in your `PATH`.
2. Clone this repository and go to the `src/` folder.
## Usage
Run the script from PowerShell:
```powershell
.\Create-IconsFromSvg.ps1
```
### Optional parameters
- `-SvgFolder`: SVG folder (default: `..\svg`)
- `-IcoFolder`: Output ICO folder (default: `..\ico`)
- `-Density`: Render density (default: `300`)

#### Example:
```powershell
.\Create-IconsFromSvg.ps1 -SvgFolder "..\svg" -IcoFolder "..\ico" -Density 300
```
### How it works
- Looks for `*-big.svg` files in the `-SvgFolder`.
- For each, finds the matching `*-small.svg` (or uses the big one if missing).
- Generates a `.ico` file with multiple resolutions (256, 64, 48 and 40 px from `*-big.svg` and 32, 24, 20, 16 px from `*-small.svg`) using ImageMagick.
- Uses SHA1 hashes to avoid regenerating icons if SVGs are unchanged.
- Output icons are saved in the `-IcoFolder` folder.
### Notes
- SVG filenames must follow the format: `name-big.svg` and `name-small.svg`.
- If the script can't determine the path of **ImageMagick** through the enviroment variable `MAGICK_CONFIGURE_PATH`. You may need to adjust the path for the variable in the script.
### `Customize-Folders.ps1`
Customizes folders by copying icons and updating desktop.ini files based on a JSON configuration.
#### Usage
Run the script from PowerShell:
```powershell
.\Customize-Folders.ps1
```
#### Optional parameters
- `-JsonPath`: Path to the JSON configuration file. Default is `.\folders.json`.)
- `-IconsPath`: Path to the folder containing icon files. Default is `..\ico\`.
#### Example:
```powershell
.\Customize-Folders.ps1 -JsonPath ".\folders.json" -IconsPath "..\ico"
```
## Changelog
See the [Changelog](CHANGELOG.md) for more details.
## Maintainer
[@Luiyi](https://github.com/lperezperez)
## Contribute
This repository follows the [Contributors covenant code of conduct](CODE_OF_CONDUCT.md).
## License
Under the terms of the [MIT](LICENSE.md) License.