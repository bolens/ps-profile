# Sync-GitRepos

## Synopsis

Syncs multiple Git repositories.

## Description

Performs git pull on multiple repositories to keep them up to date.

## Signature

```powershell
Sync-GitRepos
```

## Parameters

### -RepositoryPaths

Array of repository paths to sync. If not specified, searches for Git repositories in the current directory and subdirectories.

### -Recurse

Search for repositories recursively in subdirectories.

### -MaxDepth

Maximum depth to search when recursing. Defaults to 3.


## Outputs

System.Collections.Hashtable. Results for each repository.


## Examples

### Example 1

`powershell
Sync-GitRepos -RepositoryPaths @("C:\Repo1", "C:\Repo2")
        
        Syncs the specified repositories.
``

### Example 2

`powershell
Sync-GitRepos -Recurse -MaxDepth 2
        
        Finds and syncs all Git repositories up to 2 levels deep.
``

## Source

Defined in: ..\profile.d\git-enhanced.ps1
