# ps-profile devcontainer

Open this repository in VS Code and run **Dev Containers: Reopen in
Container**. A local Docker-compatible engine and the Dev Containers extension
are required. The first build downloads the pinned tool images and distribution
packages. Setup installs dependencies from this checkout's lockfiles and runs
`smoke.sh`. Rebuild the container after Dockerfile changes. Rerun
`bash .devcontainer/post-create.sh` after changing dependency lockfiles.

PowerShell remains on the existing CI version 7.4.7. Pester and
PSScriptAnalyzer install inside the container only. Node/Corepack, Python/uv
and Make support the repository scripts. All three editor images use Node 26. Optional data-conversion dependencies
can be installed with `uv venv && uv pip install -r requirements.txt`.
Windows-only fragments require Windows coverage.

Run from the workspace root:

```sh
pwsh -NoProfile -File scripts/utils/code-quality/run-pester-ci-shard.ps1 -Shard unit-library -Quiet
```

The editor runs as `vscode`, with its UID adjusted for the local workspace. The
source is bind-mounted at `/workspace` and is never copied into image layers.
Use a regular clone when the container cannot see a linked worktree's external
Git directory. Keep credentials in your local development environment.

`bash .devcontainer/smoke.sh` checks installed tools and checkout access. It
does not run the application test suite. No application starts automatically.
Image references include immutable digests. Dependabot monitors the Dockerfiles
where supported. Distribution packages resolve from the configured Debian
repositories at build time. Update image pins and rerun setup and native checks
together. Existing native and Nix workflows remain available independently.

The default container uses Debian 13. Choose the Ubuntu 26.04 or Arch configuration
from the Reopen in Container picker for distribution-specific tests. These
variants share the same setup scripts and pinned PowerShell runtime. Arch is
x86-64 only because its official base image does not publish ARM64.

The Editor images workflow builds all three configurations for editor and
lockfile changes. It copies the read-only checkout into a container-owned
workspace, runs the actual post-create setup as `vscode`, checks Markdown and
runs the existing `unit-library` Pester shard. PowerShell remains pinned to
7.4.7. The Ubuntu installer resolves the distribution's ICU package rather
than requiring Ubuntu 24.04's `libicu74` name.
