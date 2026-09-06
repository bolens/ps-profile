# Data model

- **Inventory entry**: label, runner OS, container, shard. The existing matrix defines validity.
- **Estimate**: platform/shard key and positive duration in seconds; provenance identifies the measured run. Unknown future estimates use a conservative default, never omit work.
- **Job entry**: label, OS, container, unique job name, ordered shard list, estimated seconds. All entries share the same platform tuple.
- **Result**: shard, checked-out revision, start/end/duration, native exit code or setup/collection failure, artifact path.

A shard progresses from pending through setup and execution to collection and cleanup. Any failed phase makes its final result fail. The job fails if any result fails.
