![Banner.svg](Banner.svg "Windows 11 Icons")
[![Latest version: 0.1.0](https://img.shields.io/badge/version-0.1.0-0b41cd.svg?label=Version&logo=V&logoColor=fff)](https://code.roche.com/necsia-team/customer-masterdata/-/tags/0.1.0)
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
- [Changelog](#changelog)
- [Maintainer](#maintainer)
- [Contribute](#contribute)
- [License](#license)

## Legal Notice
> The icons provided in this repository may include trademarks, registered trademarks, or branded logos. Their use is permitted **solely for personal purposes**. Any other use, including but not limited to commercial applications, redistribution, or modification, **requires explicit permission** from the copyright holder of the respective trademark or logo.
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
cd src
.\Create-IconsFromSvg.ps1
```
### Optional parameters
- `-SvgFolder`: SVG folder (default: `..\svg`)
- `-IcoFolder`: Output ICO folder (default: `..\ico`)
- `-Density`: Render density (default: `300`)

#### Example:
```powershell
.\Create-IconsFromSvg.ps1 -SvgFolder ".\svg" -IcoFolder ".\ico" -Density 300
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
## Changelog
See the [Changelog](CHANGELOG.md) for more details.
## Maintainer
[@Luiyi](https://github.com/lperezperez)
## Contribute
This repository follows the [Contributors covenant code of conduct](CODE_OF_CONDUCT.md).
## License
Under the terms of the [MIT](LICENSE.md) License.