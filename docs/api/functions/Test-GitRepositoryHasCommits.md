# Test-GitRepositoryHasCommits

## Synopsis

Checks whether the current Git repository has at least one commit.

## Description

Calls `git show-ref --quiet HEAD` and resets $LASTEXITCODE so higher-level helpers stay quiet on empty repos.

## Signature

```powershell
Test-GitRepositoryHasCommits
```

## Parameters

### -CommandName

Friendly name for the caller, used in verbose skip messaging.


## Outputs

System.Boolean. Returns $true when the repository contains commits.


## Examples

### Example 1

```powershell
Test-GitRepositoryHasCommits -CommandName 'Get-GitStatus'
```

## Source

Defined in: ../profile.d/git-modules/core/git-helpers.ps1
