# Woodpecker validation

Run the existing changelog policy checker on Python 3.14, followed by the locked
Markdown and spelling checks on Node 24 and the README link checker at a recorded
package version. The changelog checker uses the standard library and validates
the tracked changelog without generating or rewriting it.

## CI groups and local commands

The workflow keeps its existing `woodpecker` identity so required status names
remain stable. Use these repository commands to reproduce each group:

| Group | Woodpecker step | Local command |
| --- | --- | --- |
| Validate | `validate-changelog` | `python3 scripts/check-changelog.py` |
| Validate | `documents` | `pnpm exec markdownlint` with the tracked pipeline's file list; `pnpm exec cspell "**/*" --no-progress --no-summary`; `pnpm dlx markdown-link-check@3.15.0 README.md` |
| Test | Existing hosted PowerShell checks | `make validate`; `make test` in an isolated `pwsh -NoProfile` environment |
| Publish | Existing Release workflow | Protected-main semantic-release; no local publication command |

Use the frozen pnpm lockfile before local document checks. Portable changelog
and document validation does not replace Pester, platform checks, security
checks or the release authority.

## Acceptance and recovery

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

The pnpm overrides pin security fixes for YAML/TOML parsing and the Markdown
linter’s glob matcher while upstream dependency ranges catch up. The matcher
override is limited to markdownlint-cli; its glob and ignore behavior must pass
with the repository checks. Keep release-age protections enabled, rerun a frozen
install and the moderate-or-higher audit gate, and remove overrides when upstream
ranges include the fixes. Existing runtime dependency overrides remain separate.
