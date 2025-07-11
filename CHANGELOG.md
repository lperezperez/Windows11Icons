# Changelog
[![Semantic Versioning 2.0.0](https://img.shields.io/badge/version-2.0.0-3f4551.svg?label=Semantic%20Versioning&logo=semver)](https://semver.org/spec/v2.0.0.html) [![Keep a Changelog 1.1.0](https://img.shields.io/badge/changelog-Keep%20a%20Changelog%201.1.0-ed4a0d.svg?logo=keepachangelog)](http://keepachangelog.com/en/1.1.0/)

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.1.0/) and tries to adhere (due to the nature of the project itself), to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).
## 1.3.0 - 2025-06-16
### Added
- [`Customize-Folders.ps1`](https://github.com/lperezperez/Windows11Icons/blob/master/src/Customize-Folders.ps1) to customize folders with the icons.
- [`schema.json`](https://github.com/lperezperez/Windows11Icons/blob/master/src/schema.json) to provide the ruleset to generate JSON folders array.
- [`folders.json`](https://github.com/lperezperez/Windows11Icons/blob/master/src/folders.json) the default folder collection to customize.
## 1.2.0 - 2025-06-06
### Added
- 4 new folder icons.
- 2 new library icons.
### Changed
- [`Create-IconsFromSvg.ps1`](./src/Create-IconsFromSvg.ps1) script.
### Removed
- Gray SVG folder.
## 1.1.0 - 2025-06-02
### Changed
- Moved the [gray SVG folder](./svg/templates/folder-gray.svg) to [templates folder](./svg/templates).
- Renamed the [generic SVG folder](./svg/templates/folder.svg) to [templates folder](./svg/templates).
## 1.0.0 - 2025-06-02
### Added
- [ChangeLog](CANGELOG.md).
- [Code of conduct](CODE_OF_CONDUCT.md).
- [Script](./src/Resolve-TruePath.ps1) to resolve `magick` real path.
### Changed
- [Script](./src/Create-IconsFromSvg.ps1) to automate the process to create icons.
- [ReadMe](README.md).
- Moved the [generic SVG folder](./svg/templates/folder.svg) to [templates folder](./svg/templates).
## 0.1.0 - 2025-06-01
### Added
- Initial code.
- [ReadMe](README.md).
- [License](LICENSE.md).