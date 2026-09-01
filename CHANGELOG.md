# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.10.12] - 2026-08-08
### Fixed

- Harden validation and coverage workflows
## [1.10.11] - 2026-07-20
### Fixed

- Align CodeQL with actions-only analysis
## [1.10.10] - 2026-07-20
### Fixed

- Harden workflows and stabilize Pester CI
## [1.10.9] - 2026-06-14
### Fixed

- Drop doc cache restore from freshness check
## [1.10.8] - 2026-06-14
### Fixed

- Scan GitHub Actions workflows with CodeQL
## [1.10.7] - 2026-06-14
### Fixed

- Repair CodeQL and doc freshness checks
## [1.10.6] - 2026-06-14
### Fixed

- Resolve audit issues and standardize on pnpm
## [1.10.5] - 2026-06-14
### Fixed

- Dedupe parsed commands for deterministic API doc generation
## [1.10.4] - 2026-06-14
### Fixed

- Resolve glob CVE-2025-64756 via markdownlint-cli upgrade
- Remove volatile API README timestamp
- Stop writing Generated timestamp in API index generator
- Satisfy MD060 table spacing in requirements README
## [1.10.3] - 2026-06-13
### Fixed

- Load bootstrap first in idempotency check and refresh API docs
## [1.10.2] - 2026-06-13
### Fixed

- Resolve idempotency output, deps version check, and refresh API docs
## [1.10.1] - 2026-06-13
### Fixed

- Enable pnpm in workflows and repair -Parallel flag
- Restore spellcheck and pin markdownlint-cli version
- Ignore pnpm-lock.yaml in cspell scan
- Scope markdownlint and clear curated doc violations
- Repair security scan false positives and release cliff cmd
- Install git-cliff from release tarball in Release workflow
## [1.10.0] - 2026-06-08
### Added

- Add extended unit converters and doc tooling
## [1.9.0] - 2026-06-08
### Added

- Add bootstrap modules, doc tooling, compression/conversion utilities
## [1.8.0] - 2026-06-08
### Added

- Extend ISBN utilities; prune stale docs
## [1.7.0] - 2026-06-08
### Added

- Add unit/doc conversion modules, remove monolithic fragments
- Rebuild enhanced fragments as modular structure, expand docs
- Add ISBN and regex-description utilities
### Fixed

- Alternate command lookup and alias cleanup
- Fix fragment loader typos and test-mode profile bypass
## [1.6.0] - 2026-05-29
### Added

- Load requirements from list files and add Linux/dnf support
## [1.5.0] - 2026-05-29
### Added

- Sync drift tasks, task parity, and cross-platform doc links
### Fixed

- Opt into Node.js 24 for all workflows using JS actions
- Remove nonexistent -CacheResult param from Invoke-ScriptAnalyzer
- Add technical terms and tool names to cspell wordlist
- Remove incompatible workflows and fix matrix/node version issues
- Correct env var path bug in NodeJs/Python runtime modules; fix library-module and tool-wrapper tests
## [1.4.1] - 2026-05-28
### Fixed

- Correct action versions and missing scripts across all workflows
## [1.4.0] - 2026-05-28
### Added

- Integrate fallow and drift
### Fixed

- Repair broken links and remove stale references
## [1.3.6] - 2026-05-28
### Fixed

- Replace $env:TEMP and hardcoded Windows paths for cross-platform compat
- Fix strict-mode crash in Cache.psm1, resolve LogLevel type error, replace [ExitCode]:: with \$EXIT_* constants across all scripts
## [1.3.5] - 2026-05-28
### Fixed

- Ansible cross-platform, CRLF newlines in asn1/edifact
## [1.3.4] - 2026-05-28
### Fixed

- Cross-platform temp dir and clipboard
## [1.3.3] - 2026-05-28
### Fixed

- Audit pass — dedup functions, fix yarn typo, add missing Remove-YarnPackage
- Restore encoding modules, add doc blocks, cross-platform Linux compat
- Migrate base32-encode to v2 ESM API, bump to ^2.0.0
- Cross-platform compat for speedtest, ruby gems, Java paths, PATH separator
## [1.3.2] - 2026-01-16
### Changed

- Optimize profile loading performance and consolidate fragment output
### Fixed

- Correct module import paths and improve CommonEnums loading
- Defer PathResolution import to avoid parse-time FileSystemPathType error
- Import CommonEnums in SafeImport before Validation to ensure FileSystemPathType is available
## [1.3.1] - 2025-11-25
### Fixed

- Correct module import order in pre-commit hook
- Add -Global flag to module imports in pre-commit hook
- Correct module import order in validate-profile script
- Correct module import order in validation and utility scripts
- Normalize line endings to LF in formatter
- Add null checks to prevent null reference errors in security scanner
- Comprehensive fixes for validation, security, and gitignore
## [1.3.0] - 2025-11-13
### Added

- Enhance testing capabilities and fix integration tests
- Significantly improve test coverage
## [1.2.2] - 2025-11-05
### Fixed

- Update pre-commit hook installation to use pre-commit.ps1
## [1.2.1] - 2025-11-05
### Fixed

- Remove invalid Suppressions key and update lint report location
## [1.2.0] - 2025-11-04
### Added

- Implement Quick Wins and standardize code style
- Implement Enhanced Error Handling and Smart Prompt
- Implement additional quick wins for PowerShell profile
## [1.1.2] - 2025-10-31
### Fixed

- Resolve all markdownlint formatting issues
## [1.1.0] - 2025-10-31
### Added

- Add Add-Path function for PATH manipulation
### Fixed

- Remove trailing spaces from docs/README.md
- Remove PSScriptAnalyzer -SettingsPath warning
## [1.0.2] - 2025-10-29
### Fixed

- Resolve additional CI/CD failures
## [1.0.1] - 2025-10-29
### Fixed

- Resolve CI/CD failures
## [1.0.0] - 2025-10-29
### Fixed

- Prevent multiple trailing newlines in formatted files
