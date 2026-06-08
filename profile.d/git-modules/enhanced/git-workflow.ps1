# ===============================================
# git-workflow.ps1
# Git workflow helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env, git
<#
.SYNOPSIS
    Git workflow helpers
.DESCRIPTION
    Worktrees, sync, branch cleanup, stats, commit format, large files.
.NOTES
    Loaded by git-enhanced.ps1 or directly.
#>
try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'git-workflow') { return }
    }
    # ===============================================
    # Git Worktree - Worktree management
    # ===============================================

    <#
    .SYNOPSIS
        Creates a new Git worktree.
    

    .DESCRIPTION
        Creates a new worktree for a Git repository. Worktrees allow you to
        have multiple working directories for a single repository.
    

    .PARAMETER Path
        Path where the new worktree should be created.
    

    .PARAMETER Branch
        Branch name to checkout in the new worktree. If not specified, creates
        a new branch.
    

    .PARAMETER CreateBranch
        Create a new branch for the worktree.
    

    .PARAMETER RepositoryPath
        Path to the Git repository. Defaults to current directory.
    

    .OUTPUTS
        System.String. Path to the created worktree.

    .EXAMPLE
        New-GitWorktree -Path "../myrepo-feature" -Branch "feature/new-feature"
        
        Creates a new worktree at ../myrepo-feature and checks out the feature/new-feature branch.
    

    .EXAMPLE
        New-GitWorktree -Path "../myrepo-hotfix" -CreateBranch
        
        Creates a new worktree and a new branch.
    #>
    function New-GitWorktree {
        [CmdletBinding(SupportsShouldProcess = $true)]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Path,
            
            [string]$Branch,
            
            [switch]$CreateBranch,
            
            [string]$RepositoryPath = (Get-Location).Path
        )

        if (-not (Test-CachedCommand 'git')) {
            Invoke-MissingToolWarning -ToolName 'git'
            return
        }

        if (-not (Test-Path -LiteralPath (Join-Path $RepositoryPath '.git'))) {
            Write-Error "Not a Git repository: $RepositoryPath"
            return
        }

        if (-not $PSCmdlet.ShouldProcess($Path, "Create Git worktree")) {
            return
        }

        $arguments = @('worktree', 'add')
        
        if ($CreateBranch -and $Branch) {
            $arguments += '-b', $Branch
        }
        elseif ($Branch) {
            $arguments += $Branch
        }
        
        $arguments += $Path

        # Use standardized error handling if available
        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName "git.worktree.create" -Context @{
                repository_path = $RepositoryPath
                path            = $Path
                branch          = $Branch
                create_branch   = $CreateBranch.IsPresent
            } -ScriptBlock {
                Push-Location $RepositoryPath
                try {
                    & git $arguments
                    if ($LASTEXITCODE -eq 0) {
                        return $Path
                    }
                    else {
                        throw "Failed to create worktree. Exit code: $LASTEXITCODE"
                    }
                }
                finally {
                    Pop-Location
                }
            }
        }
        else {
            # Fallback to original implementation
            try {
                Push-Location $RepositoryPath
                & git $arguments
                if ($LASTEXITCODE -eq 0) {
                    return $Path
                }
                else {
                    Write-Error "Failed to create worktree. Exit code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Error "Failed to create Git worktree: $_"
            }
            finally {
                Pop-Location
            }
        }
    }

    # ===============================================
    # Sync Git Repositories
    # ===============================================

    <#
    .SYNOPSIS
        Syncs multiple Git repositories.
    

    .DESCRIPTION
        Performs git pull on multiple repositories to keep them up to date.
    

    .PARAMETER RepositoryPaths
        Array of repository paths to sync. If not specified, searches for
        Git repositories in the current directory and subdirectories.
    

    .PARAMETER Recurse
        Search for repositories recursively in subdirectories.
    

    .PARAMETER MaxDepth
        Maximum depth to search when recursing. Defaults to 3.
    

    .OUTPUTS
        System.Collections.Hashtable. Results for each repository.

    .EXAMPLE
        Sync-GitRepos -RepositoryPaths @("C:\Repo1", "C:\Repo2")
        
        Syncs the specified repositories.
    

    .EXAMPLE
        Sync-GitRepos -Recurse -MaxDepth 2
        
        Finds and syncs all Git repositories up to 2 levels deep.
    #>
    function Sync-GitRepos {
        [CmdletBinding()]
        [OutputType([hashtable])]
        param(
            [string[]]$RepositoryPaths,
            
            [switch]$Recurse,
            
            [int]$MaxDepth = 3
        )

        if (-not (Test-CachedCommand 'git')) {
            Invoke-MissingToolWarning -ToolName 'git'
            return @{}
        }

        $results = @{}

        if (-not $RepositoryPaths) {
            if ($Recurse) {
                $currentPath = (Get-Location).Path
                $depth = 0
                $RepositoryPaths = Get-ChildItem -Path $currentPath -Directory -Recurse -Depth $MaxDepth | 
                Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName '.git') } | 
                Select-Object -ExpandProperty FullName
            }
            else {
                $currentPath = (Get-Location).Path
                if (Test-Path -LiteralPath (Join-Path $currentPath '.git')) {
                    $RepositoryPaths = @($currentPath)
                }
            }
        }

        foreach ($repoPath in $RepositoryPaths) {
            if (-not (Test-Path -LiteralPath (Join-Path $repoPath '.git'))) {
                $results[$repoPath] = @{ Success = $false; Error = 'Not a Git repository' }
                continue
            }

            try {
                Push-Location $repoPath
                $output = & git pull 2>&1
                $success = $LASTEXITCODE -eq 0
                $results[$repoPath] = @{
                    Success = $success
                    Output  = $output
                    Error   = if (-not $success) { "Exit code: $LASTEXITCODE" } else { $null }
                }
            }
            catch {
                $results[$repoPath] = @{ Success = $false; Error = $_.Exception.Message }
            }
            finally {
                Pop-Location
            }
        }

        return $results
    }

    # ===============================================
    # Clean Git Branches
    # ===============================================

    <#
.SYNOPSIS
        Cleans up merged Git branches.
    

    .DESCRIPTION
        Removes local branches that have been merged into the current branch
        or the specified target branch. Excludes protected branches like
        main, master, and develop.
    

    .PARAMETER TargetBranch
        Target branch to check for merged branches. Defaults to current branch.
    

    .PARAMETER ExcludeBranches
        Additional branches to exclude from deletion. Defaults to main, master, develop.
    

    .PARAMETER Force
        Force delete branches even if they haven't been merged.
    

    .PARAMETER DryRun
        Show what would be deleted without actually deleting.
    

    .OUTPUTS
        System.String[]. List of deleted branch names.

    .EXAMPLE
    Clean-GitBranches -TargetBranch 'value' -ExcludeBranches @()
        Removes all merged branches from the current branch.
    

    .EXAMPLE
        Clean-GitBranches -TargetBranch "main" -DryRun
        
        Shows what branches would be deleted without actually deleting them.
#>
    function Clean-GitBranches {
        [CmdletBinding(SupportsShouldProcess = $true)]
        [OutputType([string[]])]
        param(
            [string]$TargetBranch,
            
            [string[]]$ExcludeBranches = @('main', 'master', 'develop'),
            
            [switch]$Force,
            
            [switch]$DryRun
        )

        if (-not (Test-CachedCommand 'git')) {
            Invoke-MissingToolWarning -ToolName 'git'
            return @()
        }

        if (-not (Test-Path -LiteralPath '.git')) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.ArgumentException]::new("Not a Git repository"),
                    "NotGitRepository",
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    (Get-Location).Path
                )
                Write-StructuredError -ErrorRecord $errorRecord -OperationName "git.branches.clean" -Context @{
                    target_branch = $TargetBranch
                }
            }
            else {
                Write-Error "Not a Git repository"
            }
            return @()
        }

        if (-not $TargetBranch) {
            $TargetBranch = & git rev-parse --abbrev-ref HEAD
        }

        $mergedBranches = & git branch --merged $TargetBranch | 
        ForEach-Object { $_.Trim().TrimStart('*', ' ') } | 
        Where-Object { 
            $_ -and 
            $_ -ne $TargetBranch -and 
            $_ -notin $ExcludeBranches 
        }

        if (-not $mergedBranches) {
            Write-Verbose "No merged branches to clean"
            return @()
        }

        $deletedBranches = @()

        foreach ($branch in $mergedBranches) {
            if ($DryRun) {
                Write-Host "Would delete branch: $branch"
                $deletedBranches += $branch
            }
            elseif ($PSCmdlet.ShouldProcess($branch, "Delete merged branch")) {
                try {
                    if ($Force) {
                        & git branch -D $branch
                    }
                    else {
                        & git branch -d $branch
                    }
                    if ($LASTEXITCODE -eq 0) {
                        $deletedBranches += $branch
                    }
                }
                catch {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Failed to delete branch $branch : $_" -OperationName "git.branches.clean" -Context @{
                            branch        = $branch
                            target_branch = $TargetBranch
                        }
                    }
                    else {
                        Write-Warning "Failed to delete branch $branch : $_"
                    }
                }
            }
        }

        return $deletedBranches
    }

    # ===============================================
    # Get Git Statistics
    # ===============================================

    <#
.SYNOPSIS
        Gets Git repository statistics.
    

    .DESCRIPTION
        Calculates various statistics about a Git repository including
        commit counts, contributor information, and file statistics.
    

    .PARAMETER RepositoryPath
        Path to the Git repository. Defaults to current directory.
    

    .PARAMETER Since
        Only count commits since this date.
    

    .PARAMETER Until
        Only count commits until this date.
    

    .OUTPUTS
        System.Management.Automation.PSCustomObject. Repository statistics.

    .EXAMPLE
    Get-GitStats -RepositoryPath 'value' -Since 'value'
        Gets statistics for the current repository.
    

    .EXAMPLE
        Get-GitStats -Since "2024-01-01"
        
        Gets statistics for commits since January 1, 2024.
#>
    function Get-GitStats {
        [CmdletBinding()]
        [OutputType([PSCustomObject])]
        param(
            [string]$RepositoryPath = (Get-Location).Path,
            
            [string]$Since,
            
            [string]$Until
        )

        if (-not (Test-CachedCommand 'git')) {
            Invoke-MissingToolWarning -ToolName 'git'
            return
        }

        if (-not (Test-Path -LiteralPath (Join-Path $RepositoryPath '.git'))) {
            Write-Error "Not a Git repository: $RepositoryPath"
            return
        }

        try {
            Push-Location $RepositoryPath

            $dateFilter = @()
            if ($Since) {
                $dateFilter += '--since', $Since
            }
            if ($Until) {
                $dateFilter += '--until', $Until
            }

            $totalCommits = [int](& git rev-list --count HEAD $dateFilter)
            $contributors = & git shortlog -sn $dateFilter | Measure-Object -Line | Select-Object -ExpandProperty Lines
            $totalFiles = [int](& git ls-files | Measure-Object -Line | Select-Object -ExpandProperty Lines)
            $totalLines = [int](& git ls-files -z | ForEach-Object { if ($_ -ne "`0") { Get-Content $_ -ErrorAction SilentlyContinue | Measure-Object -Line } } | Measure-Object -Property Lines -Sum | Select-Object -ExpandProperty Sum)
            $branches = [int](& git branch -a | Measure-Object -Line | Select-Object -ExpandProperty Lines)
            $tags = [int](& git tag | Measure-Object -Line | Select-Object -ExpandProperty Lines)

            return [PSCustomObject]@{
                Repository   = $RepositoryPath
                TotalCommits = $totalCommits
                Contributors = $contributors
                TotalFiles   = $totalFiles
                TotalLines   = $totalLines
                Branches     = $branches
                Tags         = $tags
                Since        = $Since
                Until        = $Until
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "git.stats.get" -Context @{
                    repository_path = $RepositoryPath
                    since           = $Since
                    until           = $Until
                }
            }
            else {
                Write-Error "Failed to get Git statistics: $_"
            }
        }
        finally {
            Pop-Location
        }
    }

    # ===============================================
    # Format Git Commit
    # ===============================================

    <#
    .SYNOPSIS
        Formats a Git commit message according to conventional commits.
    

    .DESCRIPTION
        Helps format commit messages following the Conventional Commits
        specification. Validates and formats commit messages.
    

    .PARAMETER Type
        Type of change: feat, fix, docs, style, refactor, perf, test, chore, etc.
    

    .PARAMETER Scope
        Optional scope of the change.
    

    .PARAMETER Description
        Short description of the change.
    

    .PARAMETER Body
        Optional longer description.
    

    .PARAMETER Footer
        Optional footer (e.g., breaking changes, issue references).
    

    .OUTPUTS
        System.String. Formatted commit message.

    .EXAMPLE
        Format-GitCommit -Type "feat" -Description "Add new feature"
        
        Formats a feature commit message.
    

    .EXAMPLE
        Format-GitCommit -Type "fix" -Scope "api" -Description "Fix authentication bug" -Body "Resolves issue with token expiration"
        
        Formats a fix commit with scope and body.
    #>
    function Format-GitCommit {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [ValidateSet('feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'chore', 'ci', 'build', 'revert')]
            [string]$Type,
            
            [string]$Scope,
            
            [Parameter(Mandatory = $true)]
            [string]$Description,
            
            [string]$Body,
            
            [string]$Footer
        )

        $message = if ($Scope) {
            "$Type($Scope): $Description"
        }
        else {
            "$Type`: $Description"
        }

        if ($Body) {
            $message += "`n`n$Body"
        }

        if ($Footer) {
            $message += "`n`n$Footer"
        }

        return $message
    }

    # ===============================================
    # Get Git Large Files
    # ===============================================

    <#
.SYNOPSIS
        Finds large files in Git history.
    

    .DESCRIPTION
        Identifies large files in the Git repository history that may be
        causing repository bloat.
    

    .PARAMETER RepositoryPath
        Path to the Git repository. Defaults to current directory.
    

    .PARAMETER MinSize
        Minimum file size in bytes to report. Defaults to 1MB.
    

    .PARAMETER Limit
        Maximum number of files to return. Defaults to 20.
    

    .OUTPUTS
        System.Management.Automation.PSCustomObject[]. Array of large file information.

    .EXAMPLE
    Get-GitLargeFiles -RepositoryPath 'value' -MinSize 1
        Finds the 20 largest files in the repository history.
    

    .EXAMPLE
        Get-GitLargeFiles -MinSize 5242880 -Limit 10
        
        Finds the 10 largest files over 5MB.
#>
    function Get-GitLargeFiles {
        [CmdletBinding()]
        [OutputType([PSCustomObject[]])]
        param(
            [string]$RepositoryPath = (Get-Location).Path,
            
            [long]$MinSize = 1048576,  # 1MB
            
            [int]$Limit = 20
        )

        if (-not (Test-CachedCommand 'git')) {
            Invoke-MissingToolWarning -ToolName 'git'
            return @()
        }

        if (-not (Test-Path -LiteralPath (Join-Path $RepositoryPath '.git'))) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.ArgumentException]::new("Not a Git repository: $RepositoryPath"),
                    "NotGitRepository",
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $RepositoryPath
                )
                Write-StructuredError -ErrorRecord $errorRecord -OperationName "git.largefiles.get" -Context @{
                    repository_path = $RepositoryPath
                    min_size        = $MinSize
                    limit           = $Limit
                }
            }
            else {
                Write-Error "Not a Git repository: $RepositoryPath"
            }
            return @()
        }

        try {
            Push-Location $RepositoryPath

            $largeFiles = & git rev-list --objects --all | 
            & git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | 
            Where-Object { $_ -match '^blob' } | 
            ForEach-Object {
                $parts = $_ -split '\s+', 4
                if ($parts.Length -ge 4) {
                    [PSCustomObject]@{
                        ObjectName = $parts[1]
                        Size       = [long]$parts[2]
                        Path       = $parts[3]
                    }
                }
            } | 
            Where-Object { $_.Size -ge $MinSize } | 
            Sort-Object -Property Size -Descending | 
            Select-Object -First $Limit

            return $largeFiles
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "git.largefiles.get" -Context @{
                    repository_path = $RepositoryPath
                    min_size        = $MinSize
                    limit           = $Limit
                }
            }
            else {
                Write-Error "Failed to get large files: $_"
            }
            return @()
        }
        finally {
            Pop-Location
        }
    }

    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'git-workflow'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'git-workflow' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load git-workflow: "
    }
}
