# Format-GitCommit

## Synopsis

Formats a Git commit message according to conventional commits.

## Description

Helps format commit messages following the Conventional Commits specification. Validates and formats commit messages.

## Signature

```powershell
Format-GitCommit
```

## Parameters

### -Type

Type of change: feat, fix, docs, style, refactor, perf, test, chore, etc.

### -Scope

Optional scope of the change.

### -Description

Short description of the change.

### -Body

Optional longer description.

### -Footer

Optional footer (e.g., breaking changes, issue references).


## Outputs

System.String. Formatted commit message.


## Examples

### Example 1

`powershell
Format-GitCommit -Type "feat" -Description "Add new feature"
        
        Formats a feature commit message.
``

### Example 2

`powershell
Format-GitCommit -Type "fix" -Scope "api" -Description "Fix authentication bug" -Body "Resolves issue with token expiration"
        
        Formats a fix commit with scope and body.
``

## Source

Defined in: ..\profile.d\git-enhanced.ps1
