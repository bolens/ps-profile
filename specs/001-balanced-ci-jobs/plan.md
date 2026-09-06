# Implementation Plan: Balanced CI jobs

**Branch**: `ci/avoid-redundant-coverage` | **Date**: 2026-09-06 | **Spec**: [spec.md](spec.md)

## Summary

Pack the authoritative shard/platform matrix into a bounded set of compatible jobs using longest-processing-time assignment. Run up to two shards concurrently in separate worker processes, fresh local clones, and temporary directories, through its existing entrypoint. Preserve reports and failure status across the bundle.

## Technical Context

**Language/Version**: PowerShell 7; GitHub Actions YAML.

**Primary Dependencies**: Existing Pester 5.7.x, Git, ModuleImport, ExitCodes, PathResolution, Platform, Logging.

**Storage**: Local temporary clones; job-owned artifact directory outside clones; checked-in scheduling estimates.

**Testing**: Focused Pester inventory and execution fixtures, native full validation, exact-head hosted workflow.

**Target Platform**: Existing Ubuntu, Windows, and Arch matrix; portable PowerShell helpers retain macOS behavior.

**Project Type**: Internal CI scripts; no new public runtime API.

**Performance Goals**: Complete successful PR validation under 20 minutes including queueing.

**Constraints**: Preserve 86 shard/platform pairs, test modes, coverage, required aggregate identity, read-only workflow permissions, immutable action pins, and existing module installation policy.

**Scale/Scope**: 16 compatible jobs for the full inventory; smaller selections never gain extra work.

## Constitution Check

- Startup runtime and lazy/idempotent behavior remain unchanged by this feature.
- Bootstrap shared libraries through ModuleImport; reuse path, platform, logging, and exit helpers. Existing libraries have no general process execution wrapper; native invocation is limited to Git and fresh PowerShell processes.
- Maintain strict mode, exact native exit handling, and all existing platforms.
- Use isolated committed fixtures; do not install modules or alter the live profile locally.
- Run focused coverage, full native validation, separate review, and hosted platform checks. Parent coverage cannot trace child fixture execution; report that boundary.

Pre-design gates pass. Post-design gates pass with the cache override and error-log fixture correction described in research.md; validate both before delivery.

## Project Structure

### Documentation (this feature)

`specs/001-balanced-ci-jobs/` contains the specification, plan, research, data model, quickstart, requirements checklist, and tasks.

### Source Code (repository root)

- `scripts/utils/code-quality/modules/PesterCiJobs.psm1`: job packing and isolated execution helpers.
- `scripts/utils/code-quality/pester-ci-durations.json`: measured per-platform scheduling estimates and source run provenance.
- `scripts/utils/code-quality/run-pester-ci-job.ps1`: CLI adapter using shared exit codes.
- `.github/workflows/test-pester.yml`: consume packed matrix; preserve result and coverage uploads.
- `tests/unit/test-runner/ci/test-runner-pester-ci-jobs.tests.ps1`: inventory, failure, isolation, and report fixtures.
- `docs/guides/TESTING.md`: scheduling contract and measured result.

**Structure Decision**: Keep selection in the existing filter module and execution in the existing shard entrypoint; the new module coordinates them without duplicating their policies.
