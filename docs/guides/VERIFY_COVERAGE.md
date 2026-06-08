# Coverage Verification Guide

Supplement to the [Testing Guide](TESTING.md#coverage-analysis) for verifying per-module coverage with `analyze-coverage.ps1`. For writing tests, see [Testing Patterns](../examples/TESTING_PATTERNS.md).

## Quick Commands

```powershell
# Single module
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path scripts/lib/utilities/Command.psm1

# Entire category
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path scripts/lib/utilities

# Profile fragment or bootstrap code
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/bootstrap
```

## What to Check

For each path:

1. **Overall coverage** — target ≥ 80% for new or heavily modified code (project default in `AGENTS.md`)
2. **Tests passed** — zero failures before committing
3. **Commands executed** — should be a high percentage of commands analyzed (gaps indicate untested branches)

The script matches source files to test files by naming convention, runs Pester with coverage, and writes JSON reports. See [Testing Guide — Coverage Analysis](TESTING.md#coverage-analysis) for flags and report locations.

## Troubleshooting

If commands hang or prompt for input:

1. Close other PowerShell sessions and retry
2. Run directly in a terminal (not through an IDE task runner)
3. Check for stuck processes: `Get-Process pwsh`
4. Use an explicit binary path if needed: `& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File ...`

## Related Documentation

| Guide | Purpose |
| ----- | ------- |
| [Testing Guide](TESTING.md) | Primary reference — structure, runner flags, coverage |
| [Development Guide](DEVELOPMENT.md) | Setup, workflow, advanced runner features |
| [Testing Patterns](../examples/TESTING_PATTERNS.md) | Code examples for writing tests |
| [Test Stub Guide](TEST_VERIFICATION_MOCKING_GUIDE.md) | TestSupport stubs and isolation |
| [Tool Requirements](TOOL_REQUIREMENTS.md) | Required and optional test tools |
