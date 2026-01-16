## [1.3.2](https://github.com/bolens/ps-profile/compare/v1.3.1...v1.3.2) (2026-01-16)


### Bug Fixes

* **core:** import CommonEnums in SafeImport before Validation to ensure FileSystemPathType is available ([b28a6ba](https://github.com/bolens/ps-profile/commit/b28a6bab22435851b340ec72405e6512c320dee0))
* correct module import paths and improve CommonEnums loading ([5ba06e4](https://github.com/bolens/ps-profile/commit/5ba06e433213f98101216cb5fcec51ed2ca83770))
* **fragment:** defer PathResolution import to avoid parse-time FileSystemPathType error ([6b78b35](https://github.com/bolens/ps-profile/commit/6b78b354835029f8a2e6f94a3d74755f31e7940c))


### Performance Improvements

* **profile:** optimize profile loading performance and consolidate fragment output ([4ed4884](https://github.com/bolens/ps-profile/commit/4ed4884f6eb5907b2f9b930340096a603c3ce91d))

## [1.3.1](https://github.com/bolens/ps-profile/compare/v1.3.0...v1.3.1) (2025-11-25)


### Bug Fixes

* **checks:** correct module import order in validate-profile script ([3cc4530](https://github.com/bolens/ps-profile/commit/3cc45308a6998b0deed6fe9cd366578207e3182e))
* comprehensive fixes for validation, security, and gitignore ([683df0e](https://github.com/bolens/ps-profile/commit/683df0ec9650f9611e2b54051139ca7b1633af02))
* **format:** normalize line endings to LF in formatter ([9f94886](https://github.com/bolens/ps-profile/commit/9f94886dedd6bccd55a7a51930cf272c82832146))
* **git:** add -Global flag to module imports in pre-commit hook ([f3ef3e3](https://github.com/bolens/ps-profile/commit/f3ef3e3f38be4d37f724e5d3748a80cd3a35aae1))
* **git:** correct module import order in pre-commit hook ([40359c8](https://github.com/bolens/ps-profile/commit/40359c85efad13c48599003d416d3f6a1f28fe87))
* **scripts:** correct module import order in validation and utility scripts ([9abc8c1](https://github.com/bolens/ps-profile/commit/9abc8c1c3f2b1e7bd07c6b4da3d774caa4807f25))
* **security:** add null checks to prevent null reference errors in security scanner ([ad3e584](https://github.com/bolens/ps-profile/commit/ad3e58441e83ccf7c099c2d645cc77d5a99fdcc0))

# [1.3.0](https://github.com/bolens/ps-profile/compare/v1.2.2...v1.3.0) (2025-11-13)


### Features

* enhance testing capabilities and fix integration tests ([0e5eec3](https://github.com/bolens/ps-profile/commit/0e5eec3548035a94a8fd6c8d6e54d2e3bbdbb20f))
* significantly improve test coverage ([8826a31](https://github.com/bolens/ps-profile/commit/8826a31913990ab5c0d548277223df848d08937f))

## [1.2.2](https://github.com/bolens/ps-profile/compare/v1.2.1...v1.2.2) (2025-11-05)


### Bug Fixes

* update pre-commit hook installation to use pre-commit.ps1 ([868e013](https://github.com/bolens/ps-profile/commit/868e013c2fd9494354ea29f9a4a49dcf17170d50))

## [1.2.1](https://github.com/bolens/ps-profile/compare/v1.2.0...v1.2.1) (2025-11-05)


### Bug Fixes

* remove invalid Suppressions key and update lint report location ([2fe6133](https://github.com/bolens/ps-profile/commit/2fe613352829aaadddd14c4a97c33a41c3865b60))

# [1.2.0](https://github.com/bolens/ps-profile/compare/v1.1.2...v1.2.0) (2025-11-04)

## Features

- Implement additional quick wins for PowerShell profile ([80e75bd](https://github.com/bolens/ps-profile/commit/80e75bdff2457a22f42e70f0d038debe6830bd0a))
- Implement Enhanced Error Handling and Smart Prompt ([5c41e9f](https://github.com/bolens/ps-profile/commit/5c41e9f3e7b0c30cb34a0781ec358a04c71206ff))
- Implement Quick Wins and standardize code style ([e1a73dd](https://github.com/bolens/ps-profile/commit/e1a73dd45cc6b2bad7e3499ed2859885007078b0))

## [1.1.2](https://github.com/bolens/ps-profile/compare/v1.1.1...v1.1.2) (2025-10-31)

### Bug Fixes

- resolve all markdownlint formatting issues ([e21f761](https://github.com/bolens/ps-profile/commit/e21f7618e6eba24b61a2fe20fee5cd44f6430bc3))

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1](https://github.com/bolens/ps-profile/compare/v1.1.0...v1.1.1) (2025-10-31)

### Bug Fixes

- Remove PSScriptAnalyzer -SettingsPath warning ([48153f7](https://github.com/bolens/ps-profile/commit/48153f776b040895c322ca0de2a5a41d0c8be49e))
- Remove trailing spaces from docs/README.md ([1483cf7](https://github.com/bolens/ps-profile/commit/1483cf78586fd40c7769f60ee354e8e99efa4ac7))

## [1.1.0](https://github.com/bolens/ps-profile/compare/v1.0.2...v1.1.0) (2025-10-31)

### Features

- Add Add-Path function for PATH manipulation ([f060c89](https://github.com/bolens/ps-profile/commit/f060c89cf9201e23ec6db94db938a7b875f7b92c))

## [1.0.2](https://github.com/bolens/ps-profile/compare/v1.0.1...v1.0.2) (2025-10-29)

### Bug Fixes

- Resolve additional CI/CD failures ([260f74a](https://github.com/bolens/ps-profile/commit/260f74a1e24f1528521157e633fe78214fb1c5ff))

## [1.0.1](https://github.com/bolens/ps-profile/compare/v1.0.0...v1.0.1) (2025-10-29)

### Bug Fixes

- Resolve CI/CD failures ([e6a6ea7](https://github.com/bolens/ps-profile/commit/e6a6ea7a6163b6c20cfdafe7aac6d168dfecebf7))

## [1.0.0](https://github.com/bolens/ps-profile/compare/v0.9.9...v1.0.0) (2025-10-29)

### Bug Fixes

- Prevent multiple trailing newlines in formatted files ([cefba92](https://github.com/bolens/ps-profile/commit/cefba921f7e48b1603c98def05011d18e9226cbe))
