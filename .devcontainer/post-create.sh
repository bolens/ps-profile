#!/usr/bin/env bash
# Install checkout dependencies without starting application or host services.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
(
  cd .
  corepack install
  pnpm install --frozen-lockfile
)
pwsh -NoLogo -NoProfile -File .devcontainer/post-create.ps1
bash .devcontainer/smoke.sh
