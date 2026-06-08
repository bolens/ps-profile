# [1.10.0](https://github.com/bolens/ps-profile/compare/v1.9.0...v1.10.0) (2026-06-08)


### Features

* **conversion:** add extended unit converters and doc tooling ([d054ac0](https://github.com/bolens/ps-profile/commit/d054ac0f81d2d69ce0257855f342c6a7e2d9dc8e))

## [unreleased]

### 🚀 Features

- Add bootstrap modules, doc tooling, compression/conversion utilities
- *(conversion)* Add extended unit converters and doc tooling
## [1.8.0] - 2026-06-08

### 🚀 Features

- *(isbn)* Extend ISBN utilities; prune stale docs

### ⚙️ Miscellaneous Tasks

- Remove 99-test-missing-module.ps1
- *(release)* 1.8.0 [skip ci]
## [1.7.0] - 2026-06-08

### 🚀 Features

- *(profile)* Add unit/doc conversion modules, remove monolithic fragments
- *(profile)* Rebuild enhanced fragments as modular structure, expand docs
- *(utilities)* Add ISBN and regex-description utilities

### 🐛 Bug Fixes

- *(bootstrap,conversion)* Alternate command lookup and alias cleanup
- *(profile)* Fix fragment loader typos and test-mode profile bypass

### 🚜 Refactor

- *(deps)* Move system package manifests into requirements/
- Cross-platform hardening and bootstrap improvements
- *(docs,tests)* Update API docs and improve test coverage
- *(tests)* Move TestSupport into BeforeAll and fix artifact paths
- Modernize git aliases, node path resolution, and conversion modules
- *(tests)* Add Initialize-FragmentPerformanceThresholds helper
- *(tests)* Remove Mocking/ subdir, consolidate test support

### 📚 Documentation

- *(deps)* Wire manifests to checker and drift doc links

### 🧪 Testing

- Add extended unit tests; fix Python install cmd format

### ⚙️ Miscellaneous Tasks

- *(release)* 1.7.0 [skip ci]
## [1.6.0] - 2026-05-29

### 🚀 Features

- *(deps)* Load requirements from list files and add Linux/dnf support

### ⚙️ Miscellaneous Tasks

- *(release)* 1.6.0 [skip ci]
## [1.5.0] - 2026-05-29

### 🚀 Features

- *(tooling)* Sync drift tasks, task parity, and cross-platform doc links

### 🐛 Bug Fixes

- *(ci)* Opt into Node.js 24 for all workflows using JS actions
- *(ci)* Remove nonexistent -CacheResult param from Invoke-ScriptAnalyzer
- *(spellcheck)* Add technical terms and tool names to cspell wordlist
- *(ci)* Remove incompatible workflows and fix matrix/node version issues
- Correct env var path bug in NodeJs/Python runtime modules; fix library-module and tool-wrapper tests

### 📚 Documentation

- Add 18 missing guides to docs/guides/README.md index
- Add missing guide links to docs/README.md

### 🧪 Testing

- Remove hollow tests; replace with real assertions or explicit skips
- *(unit)* Strengthen placeholder tests with real assertions
- Replace hollow Should-Not-Throw-only tests with real behavioral assertions

### ⚙️ Miscellaneous Tasks

- Disable CodeQL workflow - no Python/JS files in repo
- Remove fallow tooling and fix Import-LibModule scoping
- *(release)* 1.5.0 [skip ci]
## [1.4.1] - 2026-05-28

### 🐛 Bug Fixes

- *(ci)* Correct action versions and missing scripts across all workflows

### ⚙️ Miscellaneous Tasks

- *(release)* 1.4.1 [skip ci]
## [1.4.0] - 2026-05-28

### 🚀 Features

- *(tooling)* Integrate fallow and drift

### 🐛 Bug Fixes

- *(docs)* Repair broken links and remove stale references

### ⚙️ Miscellaneous Tasks

- *(release)* 1.4.0 [skip ci]
## [1.3.6] - 2026-05-28

### 🐛 Bug Fixes

- *(scripts)* Replace $env:TEMP and hardcoded Windows paths for cross-platform compat
- *(scripts/lib)* Fix strict-mode crash in Cache.psm1, resolve LogLevel type error, replace [ExitCode]:: with \$EXIT_* constants across all scripts

### 🚜 Refactor

- Extract Invoke-MissingToolWarning and per-function tool guards
- Add Get-ProfileDebugLevel helper and wire ConversionBase into registry
- *(scripts/lib)* Centralize LogLevel and ExitCode enums in CommonEnums.psm1

### 📚 Documentation

- Fix stale counts, broken links, and orphan fragment docs

### ⚙️ Miscellaneous Tasks

- *(release)* 1.3.6 [skip ci]
## [1.3.5] - 2026-05-28

### 🐛 Bug Fixes

- Ansible cross-platform, CRLF newlines in asn1/edifact

### ⚙️ Miscellaneous Tasks

- *(release)* 1.3.5 [skip ci]
## [1.3.4] - 2026-05-28

### 🐛 Bug Fixes

- Cross-platform temp dir and clipboard

### ⚙️ Miscellaneous Tasks

- *(release)* 1.3.4 [skip ci]
## [1.3.3] - 2026-05-28

### 🐛 Bug Fixes

- Audit pass — dedup functions, fix yarn typo, add missing Remove-YarnPackage
- Restore encoding modules, add doc blocks, cross-platform Linux compat
- *(encoding)* Migrate base32-encode to v2 ESM API, bump to ^2.0.0
- Cross-platform compat for speedtest, ruby gems, Java paths, PATH separator

### 💼 Other

- *(deps-dev)* Bump @cspell/dict-filetypes from 3.0.14 to 3.0.15
- *(deps)* Bump the npm_and_yarn group across 1 directory with 7 updates

### 🚜 Refactor

- Migrate Get-Command -ErrorAction SilentlyContinue to Test-CachedCommand
- Split MissingToolWarnings.ps1 and database.ps1 into focused modules
- Split lang-java.ps1 into build/compilers/version modules
- Split lang-python.ps1 into pipx/env/packages modules
- Split lang-rust.ps1 into tools/audit/build modules

### 📚 Documentation

- Add file-level synopsis/description to InstallHintResolver and ToolInstallRegistry
- Trim stale split notes from bootstrap module headers

### ⚙️ Miscellaneous Tasks

- *(deps)* Bump actions/upload-artifact from 4 to 6
- *(deps)* Bump actions/cache from 4 to 5
- *(deps)* Bump actions/checkout from 4 to 6
- *(release)* 1.3.3 [skip ci]
## [1.3.2] - 2026-01-16

### 🐛 Bug Fixes

- Correct module import paths and improve CommonEnums loading
- *(fragment)* Defer PathResolution import to avoid parse-time FileSystemPathType error
- *(core)* Import CommonEnums in SafeImport before Validation to ensure FileSystemPathType is available

### ⚡ Performance

- *(profile)* Optimize profile loading performance and consolidate fragment output

### ⚙️ Miscellaneous Tasks

- *(release)* 1.3.2 [skip ci]
## [1.3.1] - 2025-11-25

### 🐛 Bug Fixes

- *(git)* Correct module import order in pre-commit hook
- *(git)* Add -Global flag to module imports in pre-commit hook
- *(checks)* Correct module import order in validate-profile script
- *(scripts)* Correct module import order in validation and utility scripts
- *(format)* Normalize line endings to LF in formatter
- *(security)* Add null checks to prevent null reference errors in security scanner
- Comprehensive fixes for validation, security, and gitignore

### 🚜 Refactor

- Massive profile refactor with documentation reorganization and test fixes

### ⚙️ Miscellaneous Tasks

- *(deps)* Bump actions/download-artifact from 4 to 6
- *(deps)* Bump actions/github-script from 7 to 8
- *(deps)* Bump github/codeql-action from 3 to 4
- *(release)* 1.3.1 [skip ci]
## [1.3.0] - 2025-11-13

### 🚀 Features

- Enhance testing capabilities and fix integration tests
- Significantly improve test coverage

### 🧪 Testing

- Fix skipped dependency tests

### ⚙️ Miscellaneous Tasks

- Sync profile updates
- Update tooling and documentation
- *(release)* 1.3.0 [skip ci]
## [1.2.2] - 2025-11-05

### 🐛 Bug Fixes

- Update pre-commit hook installation to use pre-commit.ps1

### ⚙️ Miscellaneous Tasks

- *(release)* 1.2.2 [skip ci]
## [1.2.1] - 2025-11-05

### 🐛 Bug Fixes

- Remove invalid Suppressions key and update lint report location

### 📚 Documentation

- Add markdownlint task to VS Code tasks and documentation
- Update script documentation and remove quick fix scripts

### ⚙️ Miscellaneous Tasks

- *(release)* 1.2.1 [skip ci]
## [1.2.0] - 2025-11-04

### 🚀 Features

- Implement Quick Wins and standardize code style
- Implement Enhanced Error Handling and Smart Prompt
- Implement additional quick wins for PowerShell profile

### ⚙️ Miscellaneous Tasks

- *(release)* 1.2.0 [skip ci]
## [1.1.2] - 2025-10-31

### 🐛 Bug Fixes

- Resolve all markdownlint formatting issues

### ⚙️ Miscellaneous Tasks

- *(release)* 1.1.2 [skip ci]
## [1.1.1] - 2025-10-31

### ⚙️ Miscellaneous Tasks

- *(release)* 1.1.1 [skip ci]
## [1.1.0] - 2025-10-31

### 🚀 Features

- Add Add-Path function for PATH manipulation

### 🐛 Bug Fixes

- Remove trailing spaces from docs/README.md
- Remove PSScriptAnalyzer -SettingsPath warning

### ⚙️ Miscellaneous Tasks

- *(release)* 1.1.0 [skip ci]
## [1.0.2] - 2025-10-29

### 🐛 Bug Fixes

- Resolve additional CI/CD failures

### ⚙️ Miscellaneous Tasks

- *(release)* 1.0.2 [skip ci]
## [1.0.1] - 2025-10-29

### 🐛 Bug Fixes

- Resolve CI/CD failures

### ⚙️ Miscellaneous Tasks

- *(release)* 1.0.1 [skip ci]
## [1.0.0] - 2025-10-29

### 🐛 Bug Fixes

- Prevent multiple trailing newlines in formatted files

### 🚜 Refactor

- Remove 01-paths.ps1 fragment as users handle PATH via env vars

### 📚 Documentation

- Add main README.md with overview and quick start
- Add comprehensive comment-based help to all PowerShell profile functions

### 🎨 Styling

- Apply PSScriptAnalyzer formatting to all profile fragments

### ⚙️ Miscellaneous Tasks

- *(deps)* Bump actions/checkout from 4 to 5
- *(deps)* Bump actions/setup-node from 4 to 6
- *(deps)* Bump peter-evans/create-or-update-comment from 4 to 5
- *(deps)* Bump actions/upload-artifact from 3 to 5
- *(release)* 1.0.0 [skip ci]
