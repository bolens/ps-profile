# Tasks: Balanced CI jobs

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md)

## Phase 1: Setup

- [x] T001 Record measured scheduling and isolation decisions in specs/001-balanced-ci-jobs/research.md.

## Phase 2: Foundation

- [x] T002 Isolate error-log home paths using shared environment mocks in tests/integration/error-handling/error-handling.tests.ps1.

## Phase 3: Complete validation sooner (US1)

**Goal**: Preserve exact selected work in balanced compatible jobs.

**Independent test**: Expanded jobs equal the authoritative matrix with no omissions or duplicates.

- [x] T003 [US1] Add inventory and packing contract tests in tests/unit/test-runner/ci/test-runner-pester-ci-jobs.tests.ps1.
- [x] T004 [US1] Implement packing in scripts/utils/code-quality/modules/PesterCiJobs.psm1 and measured estimates in scripts/utils/code-quality/pester-ci-durations.json.

## Phase 4: Trust failures and results (US2)

**Goal**: Preserve isolation, exact revision, all artifacts, and nonzero failure status.

**Independent test**: Synthetic committed failing and passing shards preserve distinct paths and all results.

- [x] T005 [US2] Add execution, failure, unusual-path, and report fixtures in tests/unit/test-runner/ci/test-runner-pester-ci-jobs.tests.ps1.
- [x] T006 [US2] Implement isolated execution in scripts/utils/code-quality/modules/PesterCiJobs.psm1 and shared-exit CLI scripts/utils/code-quality/run-pester-ci-job.ps1.
- [x] T007 [US2] Integrate jobs and artifact collection in .github/workflows/test-pester.yml while retaining Pester result.

## Phase 5: Verification and delivery

- [x] T008 Run focused coverage and real small-bundle validation; record results in specs/001-balanced-ci-jobs/quickstart.md.
- [x] T009 Update docs/guides/TESTING.md, refresh affected drift through generators, and complete native validation and independent review.
- [x] T010 Prepare the hosted timing for the pushed commit and delivery procedure in specs/001-balanced-ci-jobs/quickstart.md and the PR description.

## Dependencies and execution

T001 precedes T002. US1 tests precede packing implementation; US2 tests precede execution implementation.
Workflow integration requires both stories. Delivery requires all earlier validation.

Packing tests and execution-fixture design can be reviewed independently after the foundation is complete. Implementation remains coordinated in this checkout.

## Implementation strategy

First prove inventory preservation, then prove failure and isolation behavior with committed fixtures. Switch
the workflow only after both pass. Measure complete hosted elapsed time before declaring the under-20-minute
target achieved.

Hosted acceptance was verified in PR #84: the final Pester run completed in 19m36s including queue time, and all applicable checks passed. See the dated receipt in `quickstart.md`.
