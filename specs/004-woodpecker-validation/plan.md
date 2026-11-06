# Plan

The repository owns its native YAML and transition/delivery documentation.
Reuse existing check entry points and failure thresholds. Keep package installs
inside disposable CI containers. Distribution packages resolve from their
configured repositories; image digests and direct tool versions remain pinned.
Keep the live PowerShell profile and release automation separate from CI
validation. Review the complete diff, run local
focused checks and normal hooks, then observe exact-head native and host gates
before normal squash delivery. Recover through a corrective PR.
