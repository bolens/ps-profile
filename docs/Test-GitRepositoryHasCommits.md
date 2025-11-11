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

No examples provided.

## Source

Defined in: profile.d\11-git.ps1
