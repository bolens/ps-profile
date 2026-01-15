# Coverage Verification Guide

## Quick Verification Commands

Run these commands in your PowerShell terminal to verify coverage for each utility module:

```powershell
# Command.psm1 (should be >75% with new tests)
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path scripts/lib/utilities/Command.psm1

# DataFile.psm1 (should be >75% with new tests)
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path scripts/lib/utilities/DataFile.psm1

# EnvFile.psm1 (should be >75% with new test file)
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path scripts/lib/utilities/EnvFile.psm1

# RequirementsLoader.psm1 (should be >75% with new test file)
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path scripts/lib/utilities/RequirementsLoader.psm1

# CacheKey.psm1 (should pass all tests now)
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path scripts/lib/utilities/CacheKey.psm1

# All utilities at once
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path scripts/lib/utilities
```

## What to Look For

For each module, check:

1. **Overall Coverage** should be ≥ 75%
2. **Tests Passed** should match or exceed **Tests Failed** (ideally 0 failures)
3. **Commands Executed** should be a high percentage of **Commands Analyzed**

## Expected Results

| Module                  | Previous Coverage | Expected Coverage | Status                   |
| ----------------------- | ----------------- | ----------------- | ------------------------ |
| Command.psm1            | 35.14%            | >75%              | ✅ Added 25+ tests       |
| DataFile.psm1           | 66.67%            | >75%              | ✅ Fixed bug + 10+ tests |
| EnvFile.psm1            | 0%                | >75%              | ✅ Created 20+ tests     |
| RequirementsLoader.psm1 | 0%                | >75%              | ✅ Created 8+ tests      |
| CacheKey.psm1           | Unknown           | >75%              | ✅ Fixed array handling  |
| JsonUtilities.psm1      | Unknown           | >75%              | ✅ Has test files        |
| RegexUtilities.psm1     | Unknown           | >75%              | ✅ Has test files        |
| StringSimilarity.psm1   | Unknown           | >75%              | ✅ Has test files        |
| Collections.psm1        | Unknown           | >75%              | ✅ Has test files        |
| Cache.psm1              | Unknown           | >75%              | ✅ Has test files        |

## Troubleshooting

If commands hang or prompt for input:

1. Close all PowerShell windows and try again
2. Run commands directly in PowerShell terminal (not through IDE)
3. Check for running PowerShell processes: `Get-Process pwsh`
4. Try with explicit path: `& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -File ...`

## Summary of Changes

- **5 modules fixed/improved**: CacheKey, Command, DataFile, EnvFile, RequirementsLoader
- **2 new test files created**: EnvFile, RequirementsLoader
- **2 test files expanded**: Command (+25 tests), DataFile (+10 tests)
- **60+ new tests added** across all modules
- **All test file mappings updated** in analyze-coverage.ps1
