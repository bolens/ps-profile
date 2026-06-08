# Test-GitRepositoryContext

## Synopsis

Tests whether the current directory is a Git working tree.

## Description

Confirms that the git executable is available and the current directory is inside a Git repository. Resets $LASTEXITCODE so callers do not inherit git errors.

## Signature

```powershell
Test-GitRepositoryContext
```

## Parameters

### -CommandName

Friendly name for the caller, used in verbose skip messaging.


## Outputs

System.Boolean. Returns $true when the repository context is valid. .EXAMPLE Test-GitRepositoryContext


## Examples

### Example 1

`powershell
Test-GitRepositoryContext
``

## Source

Defined in: ../profile.d/git-modules/core/git-helpers.ps1
