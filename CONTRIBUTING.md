Contributing
============

Thanks for contributing to this PowerShell profile workspace. A few quick notes to
make contributions smooth:

## Local validation

Run these locally before opening a PR:

```powershell
# Format code (installs PowerShell-Beautifier to CurrentUser if needed)
pwsh -NoProfile -File scripts/utils/run-format.ps1

# Security scan (installs PSScriptAnalyzer to CurrentUser if needed)
pwsh -NoProfile -File scripts/utils/run-security-scan.ps1

# Lint (installs PSScriptAnalyzer to CurrentUser if needed)
pwsh -NoProfile -File scripts/utils/run-lint.ps1

# Idempotency smoke-test (dot-sources every fragment twice)
pwsh -NoProfile -File scripts/checks/check-idempotency.ps1

# Run tests (installs Pester to CurrentUser if needed)
pwsh -NoProfile -File scripts/utils/run_pester.ps1

# Run tests with code coverage
pwsh -NoProfile -File scripts/utils/run_pester.ps1 -Coverage

# Check for module updates
pwsh -NoProfile -File scripts/utils/check-module-updates.ps1

# Combined validation
pwsh -NoProfile -File scripts/checks/validate-profile.ps1
```

## Commit messages and hooks

We use Conventional Commits for commit messages. A valid subject looks like:

```text
feat(cli): add new command
fix: correct edge-case handling
docs: update README
```

Merge and revert commits are allowed (messages starting with "Merge " or "Revert ").

To install the local git hook wrappers that run the repository's versioned
PowerShell hooks (pre-commit, pre-push, commit-msg):

```powershell
pwsh -NoProfile -File scripts/git/install-githooks.ps1
```

The install script writes small wrapper files to `.git/` that forward to the
hook scripts in `scripts/hooks/`. On Unix-like systems you may need to make
the generated hooks executable:

```powershell
chmod +x .git/*
```

## Style notes

- Keep fragments idempotent. Use `Set-AgentModeFunction` / `Set-AgentModeAlias`
  and `Get-Command -ErrorAction SilentlyContinue` guards.
- Keep side-effecting code out of early fragments (e.g., `00-bootstrap.ps1`).
- Use clear comments and add fragment-level README files.

## Questions

If you're unsure about a change, open an issue or a draft PR and tag someone
who maintains the profile.
