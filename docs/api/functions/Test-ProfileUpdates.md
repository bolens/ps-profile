# Test-ProfileUpdates

## Synopsis

Checks for profile updates and displays changelog.

## Description

Checks if the profile repository has new commits and displays a summary of recent changes. Only shows updates once per day to avoid spam.

## Signature

```powershell
Test-ProfileUpdates
```

## Parameters

### -Force

Bypasses the once-per-day check and fetches updates immediately.

### -MaxChanges

Maximum number of recent commits to include in the changelog summary.


## Examples

### Example 1

```powershell
Test-ProfileUpdates -MaxChanges 1
```

### Example 2

```powershell
Test-ProfileUpdates -Force -MaxChanges 5
```

## Source

Defined in: ../profile.d/profile-updates.ps1
