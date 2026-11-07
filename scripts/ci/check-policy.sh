#!/usr/bin/env bash
# cspell:ignore ASKPASS NOSYSTEM
# Run the exact shared source policy used by the retained Source lint workflow.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# The tooling clone must never inherit caller indexes, worktrees, tracing or auth.
while IFS= read -r git_variable; do unset "$git_variable"; done < <(compgen -v GIT_)
unset SSH_ASKPASS SSH_ASKPASS_REQUIRE
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/bin/false
cd -- "$root"
test "$(git rev-parse --show-toplevel)" = "$root"
scratch=$(mktemp -d "${TMPDIR:-/tmp}/repository-ci-policy.XXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
export PIP_NO_CACHE_DIR=1 npm_config_cache="$scratch/npm-cache"
python3 -m venv "$scratch/venv"
"$scratch/venv/bin/pip" install --disable-pip-version-check ruff==0.15.20
export PATH="$scratch/venv/bin:$scratch:$PATH"
tooling=7603518f305fb76f7bb1b9979f2692521f633b82
git init --quiet --template= "$scratch/tooling"
git -C "$scratch/tooling" fetch --quiet --depth=1 https://github.com/bolens/.github.git "$tooling"
git -C "$scratch/tooling" checkout --quiet --detach FETCH_HEAD
test "$(git -C "$scratch/tooling" rev-parse HEAD)" = "$tooling"
npm ci --ignore-scripts --no-audit --no-fund --prefix "$scratch/tooling/tools/source-lint"
python3 "$scratch/tooling/scripts/lint-source.py" "$root"
