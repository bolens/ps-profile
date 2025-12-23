# git-enhanced.ps1

Enhanced Git tools and workflows fragment.

## Overview

The `git-enhanced.ps1` fragment provides wrapper functions for advanced Git tools and workflows, including:

- **Changelog generation** with git-cliff
- **Git GUI clients** (Git Tower, GitKraken)
- **Workflow tools** (Git Butler, Jujutsu)
- **Worktree management** for multiple working directories
- **Repository synchronization** across multiple repos
- **Branch cleanup** utilities
- **Repository statistics** and analysis
- **Commit message formatting** following Conventional Commits
- **Large file detection** in Git history

## Dependencies

- `bootstrap.ps1` - Core bootstrap functions
- `env.ps1` - Environment configuration
- `git.ps1` - Base Git functionality

## Functions

### New-GitChangelog

Generates a changelog from Git history using git-cliff.

**Syntax:**
```powershell
New-GitChangelog [-OutputPath <string>] [-ConfigPath <string>] [-Tag <string>] [-Latest] [<CommonParameters>]
```

**Parameters:**
- `OutputPath` - Path to save the changelog file. Defaults to `CHANGELOG.md`.
- `ConfigPath` - Path to git-cliff configuration file.
- `Tag` - Git tag to use as the starting point for the changelog.
- `Latest` - Generate changelog only for the latest tag.

**Examples:**
```powershell
# Generate changelog in current directory
New-GitChangelog

# Generate changelog for latest tag
New-GitChangelog -Latest

# Generate changelog with custom output path
New-GitChangelog -OutputPath "docs/CHANGELOG.md"

# Generate changelog from specific tag
New-GitChangelog -Tag "v1.0.0" -OutputPath "CHANGELOG.md"
```

**Alias:** `git-cliff`

**Installation:**
```powershell
scoop install git-cliff
```

---

### Invoke-GitTower

Launches Git Tower GUI in the current directory or specified repository.

**Syntax:**
```powershell
Invoke-GitTower [-RepositoryPath <string>] [<CommonParameters>]
```

**Parameters:**
- `RepositoryPath` - Path to the Git repository. Defaults to current directory.

**Examples:**
```powershell
# Open Git Tower in current directory
Invoke-GitTower

# Open Git Tower for specific repository
Invoke-GitTower -RepositoryPath "C:\Projects\MyRepo"
```

**Alias:** `git-tower`

**Installation:**
```powershell
scoop install git-tower
```

---

### Invoke-GitKraken

Launches GitKraken GUI in the current directory or specified repository.

**Syntax:**
```powershell
Invoke-GitKraken [-RepositoryPath <string>] [<CommonParameters>]
```

**Parameters:**
- `RepositoryPath` - Path to the Git repository. Defaults to current directory.

**Examples:**
```powershell
# Open GitKraken in current directory
Invoke-GitKraken

# Open GitKraken for specific repository
Invoke-GitKraken -RepositoryPath "C:\Projects\MyRepo"
```

**Alias:** `gitkraken`

**Installation:**
```powershell
scoop install gitkraken
```

---

### Invoke-GitButler

Runs Git Butler workflow commands.

**Syntax:**
```powershell
Invoke-GitButler [[-Arguments] <string[]>] [<CommonParameters>]
```

**Parameters:**
- `Arguments` - Arguments to pass to gitbutler.

**Examples:**
```powershell
# Show Git Butler status
Invoke-GitButler status

# Sync repository
Invoke-GitButler sync

# Run with multiple arguments
Invoke-GitButler -Arguments @('status', 'sync')
```

**Alias:** `gitbutler`

**Installation:**
```powershell
scoop install gitbutler-nightly
```

---

### Invoke-Jujutsu

Runs Jujutsu version control commands.

**Syntax:**
```powershell
Invoke-Jujutsu [[-Arguments] <string[]>] [<CommonParameters>]
```

**Parameters:**
- `Arguments` - Arguments to pass to jj.

**Examples:**
```powershell
# Initialize Jujutsu repository
Invoke-Jujutsu init

# Show status
Invoke-Jujutsu status

# Run with multiple arguments
Invoke-Jujutsu -Arguments @('init', 'status')
```

**Alias:** `jj`

**Installation:**
```powershell
scoop install jj
```

---

### New-GitWorktree

Creates a new Git worktree for a repository.

**Syntax:**
```powershell
New-GitWorktree -Path <string> [-Branch <string>] [-CreateBranch] [-RepositoryPath <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

**Parameters:**
- `Path` (Required) - Path where the new worktree should be created.
- `Branch` - Branch name to checkout in the new worktree. If not specified, creates a new branch.
- `CreateBranch` - Create a new branch for the worktree.
- `RepositoryPath` - Path to the Git repository. Defaults to current directory.

**Examples:**
```powershell
# Create worktree with new branch
New-GitWorktree -Path "../myrepo-feature" -Branch "feature/new-feature"

# Create worktree and new branch
New-GitWorktree -Path "../myrepo-hotfix" -CreateBranch

# Create worktree in specific repository
New-GitWorktree -Path "../worktree" -RepositoryPath "C:\Projects\MyRepo"
```

---

### Sync-GitRepos

Syncs multiple Git repositories by performing git pull.

**Syntax:**
```powershell
Sync-GitRepos [[-RepositoryPaths] <string[]>] [-Recurse] [-MaxDepth <int>] [<CommonParameters>]
```

**Parameters:**
- `RepositoryPaths` - Array of repository paths to sync. If not specified, searches for Git repositories in the current directory.
- `Recurse` - Search for repositories recursively in subdirectories.
- `MaxDepth` - Maximum depth to search when recursing. Defaults to 3.

**Examples:**
```powershell
# Sync specific repositories
Sync-GitRepos -RepositoryPaths @("C:\Repo1", "C:\Repo2")

# Find and sync all repositories recursively
Sync-GitRepos -Recurse -MaxDepth 2

# Sync current repository
Sync-GitRepos
```

**Output:**
Returns a hashtable with results for each repository:
```powershell
@{
    "C:\Repo1" = @{
        Success = $true
        Output = "Already up to date."
        Error = $null
    }
}
```

---

### Clean-GitBranches

Cleans up merged Git branches.

**Syntax:**
```powershell
Clean-GitBranches [-TargetBranch <string>] [-ExcludeBranches <string[]>] [-Force] [-DryRun] [-WhatIf] [-Confirm] [<CommonParameters>]
```

**Parameters:**
- `TargetBranch` - Target branch to check for merged branches. Defaults to current branch.
- `ExcludeBranches` - Additional branches to exclude from deletion. Defaults to main, master, develop.
- `Force` - Force delete branches even if they haven't been merged.
- `DryRun` - Show what would be deleted without actually deleting.

**Examples:**
```powershell
# Remove all merged branches
Clean-GitBranches

# Show what would be deleted
Clean-GitBranches -DryRun

# Clean branches merged into main
Clean-GitBranches -TargetBranch "main"

# Force delete branches
Clean-GitBranches -Force
```

**Output:**
Returns an array of deleted branch names.

---

### Get-GitStats

Gets Git repository statistics.

**Syntax:**
```powershell
Get-GitStats [-RepositoryPath <string>] [-Since <string>] [-Until <string>] [<CommonParameters>]
```

**Parameters:**
- `RepositoryPath` - Path to the Git repository. Defaults to current directory.
- `Since` - Only count commits since this date.
- `Until` - Only count commits until this date.

**Examples:**
```powershell
# Get statistics for current repository
Get-GitStats

# Get statistics since a date
Get-GitStats -Since "2024-01-01"

# Get statistics for date range
Get-GitStats -Since "2024-01-01" -Until "2024-12-31"
```

**Output:**
Returns a PSCustomObject with repository statistics:
```powershell
@{
    Repository = "C:\Projects\MyRepo"
    TotalCommits = 100
    Contributors = 5
    TotalFiles = 50
    TotalLines = 5000
    Branches = 10
    Tags = 3
    Since = "2024-01-01"
    Until = $null
}
```

---

### Format-GitCommit

Formats a Git commit message according to Conventional Commits specification.

**Syntax:**
```powershell
Format-GitCommit -Type <string> [-Scope <string>] -Description <string> [-Body <string>] [-Footer <string>] [<CommonParameters>]
```

**Parameters:**
- `Type` (Required) - Type of change: feat, fix, docs, style, refactor, perf, test, chore, ci, build, revert.
- `Scope` - Optional scope of the change.
- `Description` (Required) - Short description of the change.
- `Body` - Optional longer description.
- `Footer` - Optional footer (e.g., breaking changes, issue references).

**Examples:**
```powershell
# Format feature commit
Format-GitCommit -Type "feat" -Description "Add new feature"

# Format fix commit with scope
Format-GitCommit -Type "fix" -Scope "api" -Description "Fix authentication bug"

# Format commit with body and footer
Format-GitCommit -Type "docs" -Description "Update README" -Body "Added installation instructions" -Footer "Closes #123"
```

**Output:**
Returns a formatted commit message string:
```
feat(api): Add new feature

Implemented OAuth2 authentication

Closes #456
```

---

### Get-GitLargeFiles

Finds large files in Git repository history.

**Syntax:**
```powershell
Get-GitLargeFiles [-RepositoryPath <string>] [-MinSize <long>] [-Limit <int>] [<CommonParameters>]
```

**Parameters:**
- `RepositoryPath` - Path to the Git repository. Defaults to current directory.
- `MinSize` - Minimum file size in bytes to report. Defaults to 1MB (1048576).
- `Limit` - Maximum number of files to return. Defaults to 20.

**Examples:**
```powershell
# Find largest files in repository
Get-GitLargeFiles

# Find files over 5MB
Get-GitLargeFiles -MinSize 5242880

# Find top 10 largest files
Get-GitLargeFiles -Limit 10
```

**Output:**
Returns an array of PSCustomObject with large file information:
```powershell
@(
    @{
        ObjectName = "abc123..."
        Size = 2097152
        Path = "largefile.bin"
    }
)
```

---

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions check for tool availability using `Test-CachedCommand`
- Missing tools display installation hints using `Write-MissingToolWarning`
- Functions return `$null` or empty arrays when tools are unavailable
- No errors are thrown for missing tools (graceful degradation)

## Installation

Install required tools using Scoop:

```powershell
# Install all Git enhanced tools
scoop install git-cliff git-tower gitkraken gitbutler-nightly jj

# Or install individually
scoop install git-cliff      # Changelog generation
scoop install git-tower      # Git Tower GUI
scoop install gitkraken      # GitKraken GUI
scoop install gitbutler-nightly  # Git Butler workflow
scoop install jj             # Jujutsu version control
```

## Testing

The fragment includes comprehensive test coverage:

- **Unit tests**: Individual function tests with mocking
- **Integration tests**: Fragment loading and function registration
- **Performance tests**: Load time and function execution performance

Run tests:
```powershell
# Run unit tests
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/git-enhanced.ps1

# Run integration tests
Invoke-Pester tests/integration/tools/git-enhanced.tests.ps1

# Run performance tests
Invoke-Pester tests/performance/git-enhanced-performance.tests.ps1
```

## Notes

- All functions are idempotent and can be safely called multiple times
- Functions use `Set-AgentModeFunction` and `Set-AgentModeAlias` for registration
- The fragment depends on `git.ps1` for base Git functionality
- Worktree and repository management functions require Git to be installed
- GUI functions (Git Tower, GitKraken) launch external applications

## Related Fragments

- `git.ps1` - Base Git functionality and helpers
- `gh.ps1` - GitHub CLI integration

