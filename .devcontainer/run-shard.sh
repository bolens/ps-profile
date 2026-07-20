#!/usr/bin/env bash
# Build and run a Pester CI shard inside a distro Dev Container image (no IDE required).
# Usage:
#   .devcontainer/run-shard.sh ubuntu unit-library
#   .devcontainer/run-shard.sh arch coverage-smoke
set -euo pipefail

distro="${1:-}"
shard="${2:-}"
if [[ -z "${distro}" || -z "${shard}" ]]; then
  echo "Usage: $0 <ubuntu|arch> <shard-name>" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pwsh_version="${PWSH_VERSION:-7.4.7}"
image="ps-profile-devcontainer:${distro}"

case "${distro}" in
  ubuntu)
    dockerfile="${repo_root}/.devcontainer/ubuntu/Dockerfile"
    context="${repo_root}/.devcontainer"
    ;;
  arch)
    dockerfile="${repo_root}/.devcontainer/arch/Dockerfile"
    context="${repo_root}/.devcontainer"
    ;;
  *)
    echo "Unknown distro '${distro}' (expected ubuntu or arch)" >&2
    exit 2
    ;;
esac

echo "==> Building ${image}"
docker build \
  --build-arg "PWSH_VERSION=${pwsh_version}" \
  -f "${dockerfile}" \
  -t "${image}" \
  "${context}"

echo "==> Running shard '${shard}' on ${distro}"
docker run --rm \
  -e POWERSHELL_TELEMETRY_OPTOUT=1 \
  -v "${repo_root}:/workspace:rw" \
  -w /workspace \
  "${image}" \
  pwsh -NoProfile -Command "
    \$ErrorActionPreference = 'Stop'
    if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
      Register-PSRepository -Default
    }
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name Pester -MinimumVersion 5.7.0 -MaximumVersion 5.7.99 -Force -Scope CurrentUser -AllowClobber
    \$pester = Get-Module -ListAvailable Pester |
      Where-Object { \$_.Version -ge [version]'5.7.0' -and \$_.Version -lt [version]'5.8.0' } |
      Sort-Object Version -Descending |
      Select-Object -First 1
    if (-not \$pester) { throw 'Pester 5.7.x missing' }
    Import-Module Pester -RequiredVersion \$pester.Version -Force
    & pwsh -NoProfile -NonInteractive -File scripts/utils/code-quality/run-pester-ci-shard.ps1 -Shard '${shard}' -Quiet
  "
