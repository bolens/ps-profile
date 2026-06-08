# [1.7.0](https://github.com/bolens/ps-profile/compare/v1.6.0...v1.7.0) (2026-06-08)


### Bug Fixes

* **bootstrap,conversion:** alternate command lookup and alias cleanup ([50844de](https://github.com/bolens/ps-profile/commit/50844de9d76bde01d6f5796bc48b37e1c0da4419))
* **profile:** fix fragment loader typos and test-mode profile bypass ([100dd61](https://github.com/bolens/ps-profile/commit/100dd61b56ef965d022499740f4acd6f6c0e8803))


### Features

* **profile:** add unit/doc conversion modules, remove monolithic fragments ([967d8a3](https://github.com/bolens/ps-profile/commit/967d8a3d10994c325788fb51227b3c00ada06153))
* **profile:** rebuild enhanced fragments as modular structure, expand docs ([5f2e08f](https://github.com/bolens/ps-profile/commit/5f2e08ffd172c69132ab1aa09c7c93e0fee6f85e))
* **utilities:** add ISBN and regex-description utilities ([90ce144](https://github.com/bolens/ps-profile/commit/90ce14434b7c7794546c13ea3a79b8909df73d3d))

# [1.6.0](https://github.com/bolens/ps-profile/compare/v1.5.0...v1.6.0) (2026-05-29)


### Features

* **deps:** load requirements from list files and add Linux/dnf support ([15e2bab](https://github.com/bolens/ps-profile/commit/15e2bab8165df1caf61418bb8568a5e771e95892))

# [1.5.0](https://github.com/bolens/ps-profile/compare/v1.4.1...v1.5.0) (2026-05-29)


### Bug Fixes

* **ci:** opt into Node.js 24 for all workflows using JS actions ([08a4378](https://github.com/bolens/ps-profile/commit/08a437801f550dde29e85d7a7b08f007eb92cdbf))
* **ci:** remove incompatible workflows and fix matrix/node version issues ([8704916](https://github.com/bolens/ps-profile/commit/8704916b8df45481734ca1916d6ec5c93cb9cc99))
* **ci:** remove nonexistent -CacheResult param from Invoke-ScriptAnalyzer ([6ad3515](https://github.com/bolens/ps-profile/commit/6ad35158732b5c2a83b1fd0ff77ffb10173f3812))
* correct env var path bug in NodeJs/Python runtime modules; fix library-module and tool-wrapper tests ([c3f6672](https://github.com/bolens/ps-profile/commit/c3f6672f97923c248e71ab208d0c34b1e0ef5d78))
* **spellcheck:** add technical terms and tool names to cspell wordlist ([9b4c7bb](https://github.com/bolens/ps-profile/commit/9b4c7bb6924d15dd29481fb97f4167f564268c19))


### Features

* **tooling:** sync drift tasks, task parity, and cross-platform doc links ([fa0ffab](https://github.com/bolens/ps-profile/commit/fa0ffab7109bf989aae53ba82ab2ff92d8ef6b21))

## [1.4.1](https://github.com/bolens/ps-profile/compare/v1.4.0...v1.4.1) (2026-05-28)


### Bug Fixes

* **ci:** correct action versions and missing scripts across all workflows ([a6a8224](https://github.com/bolens/ps-profile/commit/a6a8224ef7a722dfe17e75bbb65d8f8cc5307fb9))

# [1.4.0](https://github.com/bolens/ps-profile/compare/v1.3.6...v1.4.0) (2026-05-28)


### Bug Fixes

* **docs:** repair broken links and remove stale references ([76a7380](https://github.com/bolens/ps-profile/commit/76a738025a78dcf45f13775c2ed771c7a764a254))


### Features

* **tooling:** integrate fallow and drift ([0de571f](https://github.com/bolens/ps-profile/commit/0de571f7d8ff48d82dfd20cca1a0142c93c20be9))

## [1.3.6](https://github.com/bolens/ps-profile/compare/v1.3.5...v1.3.6) (2026-05-28)


### Bug Fixes

* **scripts/lib:** fix strict-mode crash in Cache.psm1, resolve LogLevel type error, replace [ExitCode]:: with \$EXIT_* constants across all scripts ([bd2c9b9](https://github.com/bolens/ps-profile/commit/bd2c9b912d02712a7e84c0a9d4c0bf74a8e1add8))
* **scripts:** replace $env:TEMP and hardcoded Windows paths for cross-platform compat ([5b06aab](https://github.com/bolens/ps-profile/commit/5b06aab4d57436cb7589d45892f7fc7552a2b6fc))

## [1.3.5](https://github.com/bolens/ps-profile/compare/v1.3.4...v1.3.5) (2026-05-28)


### Bug Fixes

* ansible cross-platform, CRLF newlines in asn1/edifact ([4c69874](https://github.com/bolens/ps-profile/commit/4c69874dd811cfb4ce2d632518d1aab476016d97))

## [1.3.4](https://github.com/bolens/ps-profile/compare/v1.3.3...v1.3.4) (2026-05-28)


### Bug Fixes

* cross-platform temp dir and clipboard ([4d4a634](https://github.com/bolens/ps-profile/commit/4d4a634ee25b90476ae2539a73fb17799c6f59d5))

## [1.3.3](https://github.com/bolens/ps-profile/compare/v1.3.2...v1.3.3) (2026-05-28)


### Bug Fixes

* audit pass — dedup functions, fix yarn typo, add missing Remove-YarnPackage ([1c5c771](https://github.com/bolens/ps-profile/commit/1c5c77159e70f771a1f5b6683897d0600f02989b))
* cross-platform compat for speedtest, ruby gems, Java paths, PATH separator ([76128a5](https://github.com/bolens/ps-profile/commit/76128a5a68bd6b57f4adb2f1c229e699bae0a4d8))
* **encoding:** migrate base32-encode to v2 ESM API, bump to ^2.0.0 ([3252411](https://github.com/bolens/ps-profile/commit/32524113883c03b94584437236eee98f48e4efcb))
* restore encoding modules, add doc blocks, cross-platform Linux compat ([9f95d48](https://github.com/bolens/ps-profile/commit/9f95d48347378c601a394072e7c5495dd58082b2))

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
