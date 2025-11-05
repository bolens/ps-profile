# Contributing

Thank you for contributing to this PowerShell profile project.

## Prerequisites

All validation scripts automatically install required modules (PSScriptAnalyzer, PowerShell-Beautifier, Pester) to `CurrentUser` scope if missing.

## Local Validation

Run these checks before opening a PR:

### Using Tasks (Recommended)

**VS Code**: Press `Ctrl+Shift+P` → "Tasks: Run Task" → select a task  
**Taskfile**: Run `task <task-name>`

```powershell
# Full quality check (recommended before PR)
task quality-check

# Or individual tasks
task validate          # Full validation (format + security + lint + spellcheck + help + idempotency)
task format            # Format code
task lint              # Lint code
task test              # Run tests
task test-coverage     # Run tests with coverage
task spellcheck        # Spellcheck
task markdownlint      # Markdownlint
task pre-commit-checks # Run pre-commit checks manually
```

### Direct Script Execution

```powershell
# Full validation (format + security + lint + idempotency)
pwsh -NoProfile -File scripts/checks/validate-profile.ps1

# Individual checks
pwsh -NoProfile -File scripts/utils/run-format.ps1          # Format code
pwsh -NoProfile -File scripts/utils/run-security-scan.ps1   # Security scan
pwsh -NoProfile -File scripts/utils/run-lint.ps1            # Lint (PSScriptAnalyzer)
pwsh -NoProfile -File scripts/checks/check-idempotency.ps1  # Idempotency test
pwsh -NoProfile -File scripts/utils/run_pester.ps1         # Run tests
pwsh -NoProfile -File scripts/utils/spellcheck.ps1          # Spellcheck
pwsh -NoProfile -File scripts/utils/run-markdownlint.ps1    # Markdownlint
```

## Git Hooks

Install pre-commit, pre-push, and commit-msg hooks:

```powershell
pwsh -NoProfile -File scripts/git/install-githooks.ps1

# On Unix-like systems, make hooks executable:
chmod +x .git/hooks/*
```

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```text
feat(cli): add new command
fix: correct edge-case handling
docs: update README
refactor: simplify bootstrap logic
```

Merge and revert commits are allowed (messages starting with "Merge " or "Revert ").

## Code Style

### Fragment Guidelines

- **Idempotency**: Fragments must be safe to dot-source multiple times
  - Use `Set-AgentModeFunction` / `Set-AgentModeAlias` from `00-bootstrap.ps1`
  - Guard with `Get-Command -ErrorAction SilentlyContinue` or `Test-Path Function:\Name`
- **No Side Effects**: Avoid expensive operations during dot-sourcing
  - Defer heavy work behind `Enable-*` functions (lazy loading pattern)
  - Keep early fragments (00-09) lightweight
- **External Tools**: Always check availability before invoking

  ```powershell
  if (Test-CachedCommand 'docker') { # configure docker helpers }
  ```

### Fragment Naming

Use numeric prefixes to control load order:

- `00-09`: Core bootstrap and helpers
- `10-19`: Terminal and Git configuration
- `20-29`: Container engines and cloud tools
- `30-69`: Development tools and language-specific utilities

## Adding New Fragments

1. Create a new `.ps1` file in `profile.d/` with appropriate numeric prefix
2. Keep it focused on a single concern (e.g., `45-nextjs.ps1` for Next.js helpers)
3. Add a `README.md` in `profile.d/` documenting the fragment (optional but recommended)
4. Ensure idempotency and guard external tool calls
5. Run validation before committing

## Documentation

- Function/alias documentation is auto-generated from comment-based help
- Run `task generate-docs` or `pwsh -NoProfile -File scripts/utils/generate-docs.ps1` to regenerate
- See [PROFILE_README.md](PROFILE_README.md) for detailed technical information

## Questions

Open an issue or draft PR if you need guidance. Tag maintainers for review.
