# Get-GitStats

## Synopsis

Gets Git repository statistics.

## Description

Calculates various statistics about a Git repository including commit counts, contributor information, and file statistics.

## Signature

```powershell
Get-GitStats
```

## Parameters

### -RepositoryPath

Path to the Git repository. Defaults to current directory.

### -Since

Only count commits since this date.

### -Until

Only count commits until this date.


## Outputs

System.Management.Automation.PSCustomObject. Repository statistics.


## Examples

### Example 1

`powershell
Get-GitStats
        
        Gets statistics for the current repository.
``

### Example 2

`powershell
Get-GitStats -Since "2024-01-01"
        
        Gets statistics for commits since January 1, 2024.
``

## Source

Defined in: ..\profile.d\git-enhanced.ps1
