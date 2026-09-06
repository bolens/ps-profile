# Research: Balanced CI jobs

## Scheduling

**Decision**: Group same-platform work using measured durations and a bounded total job count. Allocate at
least one job per platform, then assign additional jobs to the platform with the largest estimated duration
per job. Pack longest shards first into the least-loaded compatible job.

**Rationale**: Run 33999907789 still had long shards queued after ten minutes despite faster loader execution. Matrix ordering alone did not ensure early admission.

**Alternatives considered**: More shards increase queue fanout; sequencing all light work behind heavy work
creates a barrier; reducing tests or platforms violates scope. Estimates affect scheduling only.

## Execution and reports

**Decision**: Local clones of the exact checked-out commit, fresh coordinator and child processes and
temporary paths; invoke the shard script inside its own clone. Copy all tests/test-artifacts and root
coverage.xml into a separate job result directory before cleanup.

**Rationale**: Test cleanup mutates repository fixtures. Existing batch runners infer roots from their own
script path and write outside ci-<shard>. Reusing a checkout or Git worktree leaves shared mutation surfaces.

**Alternatives considered**: Cleaning one checkout is weaker isolation. Blindly replacing HOME may hide modules and optional tools; audit concrete host writes instead.

## Failure contract

**Decision**: Continue after individual setup, execution, or collection errors; record each outcome and return nonzero if any failed. Preserve final summaries outside clone cleanup paths.

**Rationale**: A later successful shard must not hide earlier failure, and remaining diagnostics must be collected.

Independent scheduling review completed; targeted host-state review remains part of validation.

## Host-state audit

**Decision**: Set PS_PROFILE_CACHE_DIR to a per-shard temporary path. Keep installed-tool and module discovery
unchanged. Move the error-handling integration test's HOME/USERPROFILE to its existing test fixture for each
case, using shared environment mocks and restoration.

**Rationale**: The audit found one test deleting and reading the home error log. Other eager debug startups
only append to it; no demonstrated later test depends on those entries. Git optimization fixtures already
isolate home state. Reviewed background-job tests wait and remove their jobs. This is practical state
isolation, not a sandbox guarantee.

## Per-runner parallelism

**Decision**: Use at most two separate-process workers per hosted job; retain serial execution as the helper
default for focused use. Each worker invokes the same isolated execution path and writes a distinct summary
file. The parent retains all outcomes and owns aggregate status.

**Rationale**: The complete 3119aa2c candidate passed in 30m45s with 21,955 test-step seconds. Serial packing
still estimates more than 20 minutes on the busiest job. Separate processes permit concurrent use of runner
cores without sharing PowerShell environment variables.

**Validation**: Prove worker overlap, unique process/repo/temp/cache paths, retained failures, and
native-child termination on worker cancellation. Keep the host-state audit limitation above.

## Runner capacity

**Decision**: Default to 16 jobs (seven Ubuntu, seven Windows, two Arch), retaining the configurable budget and all 86 shard/platform pairs.

**Rationale**: The 20-job hosted candidate still queued bundles behind concurrent validation. Modeling two
workers with the same completed-run estimates gives a longest job of 838 seconds at 16 jobs versus 827 seconds
at 20. Leaving capacity for other checks should reduce queue delays; the model is not hosted timing proof.

The completed worker trial (run 34003602400) supplied all 86 execution durations, including checkout and
collection. All test executions passed; one Windows permission-fixture cleanup failed and is repaired
separately. Refreshing the scheduling estimates with these measurements moves one job from Ubuntu to Windows
and models a longest job of 928 seconds at 16 jobs. Hosted validation remains the acceptance gate.

## Timing-sensitive work

**Decision**: Performance shards have a dedicated serial Windows job. Ordinary shards retain two workers. The
full budget is 17 jobs so the dedicated job does not lengthen the other Windows groups.

**Rationale**: Run 34005288918 completed in 19m46s but failed one security-tools performance assertion while
sharing a runner with eager loader work. The quiet batch runner retained only counts, so the exact assertion
was unavailable. Keep performance thresholds unchanged, remove competing shard execution, and retain per-file
XML and captured output for diagnosis. The completed-run estimates model a longest job of about 16 minutes
with 17 jobs; only successful hosted execution establishes acceptance.

## Refresh estimates from successful runs

**Decision**: Keep the 17-job budget and use the maximum observed duration of each shard from successful runs
34006983434 and 34008071025. This allocates eight Ubuntu, seven ordinary Windows, one Arch, and one serial
Windows performance job while preserving all 86 platform/shard pairs.

**Rationale**: Complete elapsed times were 25m16s and 20m19s, including queueing. The older estimates
understated several Ubuntu shards. The refreshed estimates model a longest execution of 16m21s before runner
setup and queue delay; budgets of 18–20 jobs do not improve that maximum. Hosted validation remains the
acceptance test.
