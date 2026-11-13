# Woodpecker validation

Run the existing changelog policy checker on Python 3.14, followed by the locked
Markdown and spelling checks on Node 24 and the README link checker at a recorded
package version. The changelog checker uses the standard library and validates
the tracked changelog without generating or rewriting it.

## CI groups and local commands

The workflow keeps its existing `woodpecker` identity so required status names
remain stable. Use the [shared purpose phases](https://github.com/bolens/.github/blob/main/docs/woodpecker-transition.md#ci-organization)
and these repository commands to reproduce each group:

| Phase | Woodpecker step | Local command |
| --- | --- | --- |
| `validate` | `source-policy` | `bash scripts/ci/check-policy.sh` |
| `validate` | `validate-changelog` | `python3 scripts/check-changelog.py` |
| `validate` | `documents` | `pnpm exec markdownlint` with the tracked pipeline's file list; `pnpm exec cspell "**/*" --no-progress --no-summary`; `pnpm dlx markdown-link-check@3.15.0 README.md` |
| `test` | Existing hosted PowerShell checks | `make validate`; `make test` in an isolated `pwsh -NoProfile` environment |
| `publish` | Existing Release workflow | Protected-main semantic-release; no local publication command |

Use the frozen pnpm lockfile before local document checks. Portable changelog
and document validation does not replace Pester, platform checks, security
checks or the release authority.

## Acceptance and recovery

The pipeline runs on pull requests and main pushes with immutable clone/runtime
images. It has no host mounts, Docker socket, privileged mode or publishing
secrets. Package installation is confined to the disposable job container.
The duplicate hosted Source lint is retired after accepted native PR and main
verification. The native `ci/woodpecker/pr/woodpecker` status is required alongside
GitHub's unchanged `Pester result` and `commit-message-check`. Platform, real
Docker, security and release checks retain their own coverage and authority.
A container or lint result does not prove installation, runtime or publication.

Require exact-head PR checks, a reviewed squash merge, and genuine native main
success before retiring duplicates. Keep existing required status names until
their replacements have passed and host settings agree. Recover through a
corrective PR without changing live profiles or installations.

Review image digests monthly and after security releases. Existing Dockerfile
updaters do not monitor these Woodpecker YAML references. Direct tool pins and
image updates require a reviewed PR and successful native execution.

The pnpm overrides pin security fixes for YAML/TOML parsing and the Markdown
linter’s glob matcher while upstream dependency ranges catch up. The matcher
override is limited to markdownlint-cli; its glob and ignore behavior must pass
with the repository checks. Keep release-age protections enabled, rerun a frozen
install and the moderate-or-higher audit gate, and remove overrides when upstream
ranges include the fixes. Existing runtime dependency overrides remain separate.

The `source-policy` group runs the existing shared SourceLint selector at
`7603518f305fb76f7bb1b9979f2692521f633b82` over the complete Python and shell
sets in `.github/source-lint.json`. It uses Ruff 0.15.20 and the shared locked
tooling. Local reproduction requires Git, Node 24, Python 3 with venv support
and ShellCheck; all downloaded tooling is installed in a disposable temporary
directory. No PowerShell module or live profile is loaded or installed by this
check. Its duplicate hosted Source lint is retired. Future status migrations
still require exact-head native PR and genuine-main results and a separately
reviewed settings change that preserves every other required check.
