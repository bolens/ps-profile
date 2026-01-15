# Get-GitLargeFiles

## Synopsis

Finds large files in Git history.

## Description

Identifies large files in the Git repository history that may be causing repository bloat.

## Signature

```powershell
Get-GitLargeFiles
```

## Parameters

### -RepositoryPath

Path to the Git repository. Defaults to current directory.

### -MinSize

Minimum file size in bytes to report. Defaults to 1MB.

### -Limit

Maximum number of files to return. Defaults to 20.


## Outputs

System.Management.Automation.PSCustomObject[]. Array of large file information.


## Examples

### Example 1

`powershell
Get-GitLargeFiles
        
        Finds the 20 largest files in the repository history.
``

### Example 2

`powershell
Get-GitLargeFiles -MinSize 5242880 -Limit 10
        
        Finds the 10 largest files over 5MB.
``

## Source

Defined in: ..\profile.d\git-enhanced.ps1
