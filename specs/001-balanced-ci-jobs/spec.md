# Feature Specification: Balanced CI jobs

**Feature Branch**: `ci/avoid-redundant-coverage`

**Created**: 2026-09-06

**Status**: Implemented; hosted acceptance pending

**Input**: Improve PR CI toward under 20 minutes without losing functionality.

## User Scenarios & Testing

### User Story 1 - Receive complete validation sooner (Priority: P1)

A contributor receives every applicable platform and test result with less queueing.

**Why this priority**: Long tests currently wait behind many small jobs.

**Independent Test**: Expand scheduled work and compare it with the existing inventory.

**Acceptance Scenarios**:

1. Given all tests apply, scheduling preserves all 86 shard/platform pairs exactly once.
2. Given only selected paths change, scheduling preserves exactly their selected work.
3. Given no tests apply, the normal successful aggregate result remains available.

### User Story 2 - Trust failures and diagnose them (Priority: P1)

A contributor sees failures even when subsequent tests pass, and can inspect each result.

**Why this priority**: Faster validation must remain a reliable merge gate.

**Independent Test**: Run failing then passing fixture shards and inspect status and artifacts.

**Acceptance Scenarios**:

1. A setup, execution, or artifact collection failure makes the job fail after remaining work runs.
2. Test-created repository and temporary files cannot contaminate another shard.
3. Each result identifies the tested revision, shard, duration, and outcome.
4. Existing ordinary, batch, and coverage reports remain available after failure.

### Edge Cases

- Empty selection, duplicated or unknown shard names, invalid job limits.
- Repository paths containing spaces; detached synthetic merge commits.
- Missing reports after setup failure; artifact copy failure; cleanup failure.
- Windows-only performance tests and Arch container execution.

## Requirements

### Functional Requirements

- **FR-001**: Preserve the existing selection rules and exact platform coverage.
- **FR-002**: Schedule a bounded set of balanced jobs using measured durations; estimates never select or skip tests.
- **FR-003**: Preserve fresh process, repository, and temporary-file isolation for each shard.
- **FR-004**: Test the exact checked-out revision, including a PR merge revision.
- **FR-005**: Keep all existing assertions, test modes, coverage modes, and required merge checks.
- **FR-006**: Fail reliably on any shard or infrastructure error while retaining subsequent results.
- **FR-007**: Retain all existing result types with unique shard attribution and execution timing.
- **FR-008**: Validate inventory equivalence and failure/isolation/report behavior with focused automated tests.

### Key Entities

- Shard/platform pair: one existing independently selected validation unit.
- Job: compatible pairs assigned one runner, with estimated aggregate duration.
- Shard result: tested revision, elapsed duration, outcome, and collected reports.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A complete successful PR validation run finishes within 20 minutes, including queueing.
- **SC-002**: Inventory comparison proves zero omitted or duplicate shard/platform pairs.
- **SC-003**: Every injected failure blocks success and leaves subsequent completed results available for inspection.
- **SC-004**: Every applicable hosted check passes before merge.

## Assumptions

- Existing runner access and capacity remain unchanged; no new paid infrastructure.
- Job grouping does not promise separate virtual machines for each shard; shared home-directory and machine services remain a reviewed limitation.
- Current runtime corrections and fixture optimizations are already implemented and outside this new specification.
- The existing ungrouped inventory remains authoritative. Performance estimates are scheduling hints only.
