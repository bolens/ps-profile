# Woodpecker validation

Run the existing locked Markdown and spelling checks on Node 24, then the README link checker at a recorded package version.

The pipeline runs on pull requests and main pushes with immutable clone/runtime
images. It has no host mounts, Docker socket, privileged mode or publishing
secrets. Package installation is confined to the disposable job container.
Existing GitHub checks remain during native verification. Platform, real Docker,
security and release checks remain separate until equivalent coverage exists.
A container or lint result does not prove installation, runtime or publication.

Require exact-head PR checks, a reviewed squash merge, and genuine native main
success before retiring duplicates. Keep existing required status names until
their replacements have passed and host settings agree. Recover through a
corrective PR without changing live profiles or installations.

Review image digests monthly and after security releases. Existing Dockerfile
updaters do not monitor these Woodpecker YAML references. Direct tool pins and
image updates require a reviewed PR and successful native execution.
