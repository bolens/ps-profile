# Native Linux Pester shadow

Woodpecker runs the eight Linux bundles from the same planner as the hosted
Pester workflow. Each native bundle uses two concurrent shards, with PowerShell
7.6.10, Pester 5.7.1, and Node 26.13.1 pinned to verified downloads.
Pull requests, pushes to `main`, and manual runs exercise all 48 Linux shards.
Hosted Pester continues to run on every applicable platform and retains its
required status and artifact uploads.

## Workflow discovery

Leave the Woodpecker pipeline path blank. Woodpecker searches `.woodpecker/`
first, then falls back to the root YAML on branches that predate the directory.
The required check still comes from the workflow named `woodpecker`. Source
policy checks that its directory and fallback copies are identical. To revert
discovery, set the pipeline path back to `.woodpecker.yml`.

## Verification

Run `woodpecker lint --strict .woodpecker` and
`pwsh -NoProfile -File scripts/ci/run-native-pester.ps1 -PlanOnly` locally.
The plan must contain exactly eight disjoint Linux bundles and all 48 shards.

For admission, check the required Woodpecker status and all eight native statuses
on the same pull request revision. Verify them again on the merged main revision.
Each native job writes the exact source revision and shard names to its log and
collects test files in the job workspace. GitHub remains the durable report
store for hosted Pester. Review native skip counts, runner resources, elapsed
times, and durable native artifact storage before proposing any hosted cutover.
