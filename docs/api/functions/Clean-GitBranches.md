# Clean-GitBranches

## Synopsis

Cleans up merged Git branches.

## Description

Removes local branches that have been merged into the current branch or the specified target branch. Excludes protected branches like main, master, and develop.

## Signature

```powershell
Clean-GitBranches
```

## Parameters

### -TargetBranch

Target branch to check for merged branches. Defaults to current branch.

### -ExcludeBranches

Additional branches to exclude from deletion. Defaults to main, master, develop.

### -Force

Force delete branches even if they haven't been merged.

### -DryRun

Show what would be deleted without actually deleting.


## Outputs

System.String[]. List of deleted branch names.


## Examples

### Example 1

`powershell
Clean-GitBranches
        
        Removes all merged branches from the current branch.
``

### Example 2

`powershell
Clean-GitBranches -TargetBranch "main" -DryRun
        
        Shows what branches would be deleted without actually deleting them.
``

## Source

Defined in: ..\profile.d\git-enhanced.ps1
