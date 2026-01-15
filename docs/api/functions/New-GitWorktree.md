# New-GitWorktree

## Synopsis

Creates a new Git worktree.

## Description

Creates a new worktree for a Git repository. Worktrees allow you to have multiple working directories for a single repository.

## Signature

```powershell
New-GitWorktree
```

## Parameters

### -Path

Path where the new worktree should be created.

### -Branch

Branch name to checkout in the new worktree. If not specified, creates a new branch.

### -CreateBranch

Create a new branch for the worktree.

### -RepositoryPath

Path to the Git repository. Defaults to current directory.


## Outputs

System.String. Path to the created worktree.


## Examples

### Example 1

`powershell
New-GitWorktree -Path "../myrepo-feature" -Branch "feature/new-feature"
        
        Creates a new worktree at ../myrepo-feature and checks out the feature/new-feature branch.
``

### Example 2

`powershell
New-GitWorktree -Path "../myrepo-hotfix" -CreateBranch
        
        Creates a new worktree and a new branch.
``

## Source

Defined in: ..\profile.d\git-enhanced.ps1
