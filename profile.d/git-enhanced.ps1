# ===============================================
# git-enhanced.ps1
# Enhanced Git tools and workflows
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env, git

<#
.SYNOPSIS
    Enhanced Git tools fragment for advanced Git workflows and GUI tools.

.DESCRIPTION
    Provides wrapper functions for enhanced Git tools:
    - git-cliff: Changelog generation
    - git-tower: Git Tower GUI
    - gitkraken: GitKraken GUI
    - gitbutler: Git Butler workflow tool
    - jj: Jujutsu version control
    - git worktree: Worktree management
    - Git statistics and analysis
    - Branch cleanup and repository management

.NOTES
    All functions gracefully degrade when tools are not installed.
    Use Register-ToolWrapper for simple wrappers and custom functions for complex operations.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'git-enhanced') { return }
    }
    
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
        }
        else {
            Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        
        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # git-cliff - Changelog generation
    # ===============================================

    <#
    .SYNOPSIS
        Generates a changelog using git-cliff.
    
    .DESCRIPTION
        Creates a changelog from Git history using git-cliff. Supports
        various output formats and configuration options.
    
    .PARAMETER OutputPath
        Path to save the changelog file. Defaults to CHANGELOG.md.
    
    .PARAMETER ConfigPath
        Path to git-cliff configuration file.
    
    .PARAMETER Tag
        Git tag to use as the starting point for the changelog.
    
    .PARAMETER Latest
        Generate changelog only for the latest tag.
    
    .EXAMPLE
        New-GitChangelog
        
        Generates a changelog in the current directory.
    
    .EXAMPLE
        New-GitChangelog -OutputPath "docs/CHANGELOG.md" -Latest
        
        Generates a changelog for the latest tag and saves it to docs/CHANGELOG.md.
    
    .OUTPUTS
        System.String. Path to the generated changelog file.
    #>
    function New-GitChangelog {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$OutputPath = 'CHANGELOG.md',
            
            [string]$ConfigPath,
            
            [string]$Tag,
            
            [switch]$Latest
        )

        if (-not (Test-CachedCommand 'git-cliff')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'git-cliff' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -ToolName 'git-cliff' -InstallHint $installHint
            }
            else {
                Write-Warning "git-cliff is not installed. Install it with: scoop install git-cliff"
            }
            return
        }

        $arguments = @()
        
        if ($ConfigPath) {
            $arguments += '--config', $ConfigPath
        }
        
        if ($Tag) {
            $arguments += '--tag', $Tag
        }
        
        if ($Latest) {
            $arguments += '--latest'
        }
        
        $arguments += '--output', $OutputPath

        try {
            & git-cliff $arguments
            if ($LASTEXITCODE -eq 0) {
                return $OutputPath
            }
            else {
                Write-Error "Failed to generate changelog. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to run git-cliff: $_"
        }
    }

    # ===============================================
    # Git Tower - Git GUI
    # ===============================================

    <#
    .SYNOPSIS
        Launches Git Tower GUI.
    
    .DESCRIPTION
        Opens Git Tower, a powerful Git GUI client, in the current directory
        or specified repository path.
    
    .PARAMETER RepositoryPath
        Path to the Git repository. Defaults to current directory.
    
    .EXAMPLE
        Invoke-GitTower
        
        Opens Git Tower in the current directory.
    
    .EXAMPLE
        Invoke-GitTower -RepositoryPath "C:\Projects\MyRepo"
        
        Opens Git Tower for the specified repository.
    #>
    function Invoke-GitTower {
        [CmdletBinding()]
        param(
            [string]$RepositoryPath = (Get-Location).Path
        )

        if (-not (Test-CachedCommand 'git-tower')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'git-tower' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -ToolName 'git-tower' -InstallHint $installHint
            }
            else {
                Write-Warning "git-tower is not installed. Install it with: scoop install git-tower"
            }
            return
        }

        try {
            Start-Process -FilePath 'git-tower' -ArgumentList $RepositoryPath -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to launch Git Tower: $_"
        }
    }

    # ===============================================
    # GitKraken - Git GUI
    # ===============================================

    <#
    .SYNOPSIS
        Launches GitKraken GUI.
    
    .DESCRIPTION
        Opens GitKraken, a cross-platform Git GUI client, in the current directory
        or specified repository path.
    
    .PARAMETER RepositoryPath
        Path to the Git repository. Defaults to current directory.
    
    .EXAMPLE
        Invoke-GitKraken
        
        Opens GitKraken in the current directory.
    
    .EXAMPLE
        Invoke-GitKraken -RepositoryPath "C:\Projects\MyRepo"
        
        Opens GitKraken for the specified repository.
    #>
    function Invoke-GitKraken {
        [CmdletBinding()]
        param(
            [string]$RepositoryPath = (Get-Location).Path
        )

        if (-not (Test-CachedCommand 'gitkraken')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'gitkraken' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -ToolName 'gitkraken' -InstallHint $installHint
            }
            else {
                Write-Warning "gitkraken is not installed. Install it with: scoop install gitkraken"
            }
            return
        }

        try {
            Start-Process -FilePath 'gitkraken' -ArgumentList $RepositoryPath -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to launch GitKraken: $_"
        }
    }

    # ===============================================
    # Git Butler - Git workflow tool
    # ===============================================

    <#
    .SYNOPSIS
        Runs Git Butler workflow commands.
    
    .DESCRIPTION
        Executes Git Butler commands for managing Git workflows and operations.
        Git Butler is a modern Git workflow tool.
    
    .PARAMETER Arguments
        Arguments to pass to gitbutler.
    
    .EXAMPLE
        Invoke-GitButler status
        
        Shows Git Butler status.
    
    .EXAMPLE
        Invoke-GitButler sync
        
        Syncs the repository with Git Butler.
    
    .OUTPUTS
        System.String. Output from Git Butler command.
    #>
    function Invoke-GitButler {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'gitbutler')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'gitbutler-nightly' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -ToolName 'gitbutler' -InstallHint $installHint
            }
            else {
                Write-Warning "gitbutler is not installed. Install it with: scoop install gitbutler-nightly"
            }
            return
        }

        try {
            if ($Arguments) {
                & gitbutler $Arguments
            }
            else {
                & gitbutler
            }
        }
        catch {
            Write-Error "Failed to run gitbutler: $_"
        }
    }

    # ===============================================
    # Jujutsu - Version control
    # ===============================================

    <#
    .SYNOPSIS
        Runs Jujutsu version control commands.
    
    .DESCRIPTION
        Executes Jujutsu (jj) commands. Jujutsu is a Git-compatible version
        control system with a different mental model.
    
    .PARAMETER Arguments
        Arguments to pass to jj.
    
    .EXAMPLE
        Invoke-Jujutsu init
        
        Initializes a new Jujutsu repository.
    
    .EXAMPLE
        Invoke-Jujutsu status
        
        Shows Jujutsu repository status.
    
    .OUTPUTS
        System.String. Output from Jujutsu command.
    #>
    function Invoke-Jujutsu {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'jj')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'jj' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -ToolName 'jj' -InstallHint $installHint
            }
            else {
                Write-Warning "jj is not installed. Install it with: scoop install jj"
            }
            return
        }

        try {
            if ($Arguments) {
                & jj $Arguments
            }
            else {
                & jj
            }
        }
        catch {
            Write-Error "Failed to run jj: $_"
        }
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
    
    .EXAMPLE
        New-GitWorktree -Path "../myrepo-feature" -Branch "feature/new-feature"
        
        Creates a new worktree at ../myrepo-feature and checks out the feature/new-feature branch.
    
    .EXAMPLE
        New-GitWorktree -Path "../myrepo-hotfix" -CreateBranch
        
        Creates a new worktree and a new branch.
    
    .OUTPUTS
        System.String. Path to the created worktree.
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
            Write-Warning "git is not installed. Install it with: scoop install git"
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
    
    .EXAMPLE
        Sync-GitRepos -RepositoryPaths @("C:\Repo1", "C:\Repo2")
        
        Syncs the specified repositories.
    
    .EXAMPLE
        Sync-GitRepos -Recurse -MaxDepth 2
        
        Finds and syncs all Git repositories up to 2 levels deep.
    
    .OUTPUTS
        System.Collections.Hashtable. Results for each repository.
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
            Write-Warning "git is not installed. Install it with: scoop install git"
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
    
    .EXAMPLE
        Clean-GitBranches
        
        Removes all merged branches from the current branch.
    
    .EXAMPLE
        Clean-GitBranches -TargetBranch "main" -DryRun
        
        Shows what branches would be deleted without actually deleting them.
    
    .OUTPUTS
        System.String[]. List of deleted branch names.
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
            Write-Warning "git is not installed. Install it with: scoop install git"
            return @()
        }

        if (-not (Test-Path -LiteralPath '.git')) {
            Write-Error "Not a Git repository"
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
                    Write-Warning "Failed to delete branch $branch : $_"
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
    
    .EXAMPLE
        Get-GitStats
        
        Gets statistics for the current repository.
    
    .EXAMPLE
        Get-GitStats -Since "2024-01-01"
        
        Gets statistics for commits since January 1, 2024.
    
    .OUTPUTS
        System.Management.Automation.PSCustomObject. Repository statistics.
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
            Write-Warning "git is not installed. Install it with: scoop install git"
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
            Write-Error "Failed to get Git statistics: $_"
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
    
    .EXAMPLE
        Format-GitCommit -Type "feat" -Description "Add new feature"
        
        Formats a feature commit message.
    
    .EXAMPLE
        Format-GitCommit -Type "fix" -Scope "api" -Description "Fix authentication bug" -Body "Resolves issue with token expiration"
        
        Formats a fix commit with scope and body.
    
    .OUTPUTS
        System.String. Formatted commit message.
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
    
    .EXAMPLE
        Get-GitLargeFiles
        
        Finds the 20 largest files in the repository history.
    
    .EXAMPLE
        Get-GitLargeFiles -MinSize 5242880 -Limit 10
        
        Finds the 10 largest files over 5MB.
    
    .OUTPUTS
        System.Management.Automation.PSCustomObject[]. Array of large file information.
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
            Write-Warning "git is not installed. Install it with: scoop install git"
            return @()
        }

        if (-not (Test-Path -LiteralPath (Join-Path $RepositoryPath '.git'))) {
            Write-Error "Not a Git repository: $RepositoryPath"
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
            Write-Error "Failed to get large files: $_"
            return @()
        }
        finally {
            Pop-Location
        }
    }

    # Register functions and aliases
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'New-GitChangelog' -Body ${function:New-GitChangelog}
        Set-AgentModeFunction -Name 'Invoke-GitTower' -Body ${function:Invoke-GitTower}
        Set-AgentModeFunction -Name 'Invoke-GitKraken' -Body ${function:Invoke-GitKraken}
        Set-AgentModeFunction -Name 'Invoke-GitButler' -Body ${function:Invoke-GitButler}
        Set-AgentModeFunction -Name 'Invoke-Jujutsu' -Body ${function:Invoke-Jujutsu}
        Set-AgentModeFunction -Name 'New-GitWorktree' -Body ${function:New-GitWorktree}
        Set-AgentModeFunction -Name 'Sync-GitRepos' -Body ${function:Sync-GitRepos}
        Set-AgentModeFunction -Name 'Clean-GitBranches' -Body ${function:Clean-GitBranches}
        Set-AgentModeFunction -Name 'Get-GitStats' -Body ${function:Get-GitStats}
        Set-AgentModeFunction -Name 'Format-GitCommit' -Body ${function:Format-GitCommit}
        Set-AgentModeFunction -Name 'Get-GitLargeFiles' -Body ${function:Get-GitLargeFiles}
    }
    else {
        # Fallback: direct function registration
        Set-Item -Path Function:New-GitChangelog -Value ${function:New-GitChangelog} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Invoke-GitTower -Value ${function:Invoke-GitTower} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Invoke-GitKraken -Value ${function:Invoke-GitKraken} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Invoke-GitButler -Value ${function:Invoke-GitButler} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Invoke-Jujutsu -Value ${function:Invoke-Jujutsu} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:New-GitWorktree -Value ${function:New-GitWorktree} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Sync-GitRepos -Value ${function:Sync-GitRepos} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Clean-GitBranches -Value ${function:Clean-GitBranches} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-GitStats -Value ${function:Get-GitStats} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Format-GitCommit -Value ${function:Format-GitCommit} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-GitLargeFiles -Value ${function:Get-GitLargeFiles} -Force -ErrorAction SilentlyContinue
    }

    # Register aliases
    if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
        Set-AgentModeAlias -Name 'git-cliff' -Target 'New-GitChangelog'
        Set-AgentModeAlias -Name 'git-tower' -Target 'Invoke-GitTower'
        Set-AgentModeAlias -Name 'gitkraken' -Target 'Invoke-GitKraken'
        Set-AgentModeAlias -Name 'gitbutler' -Target 'Invoke-GitButler'
        Set-AgentModeAlias -Name 'jj' -Target 'Invoke-Jujutsu'
    }
    else {
        # Fallback: direct alias registration
        if (-not (Get-Alias -Name 'git-cliff' -ErrorAction SilentlyContinue)) {
            Set-Alias -Name 'git-cliff' -Value 'New-GitChangelog' -ErrorAction SilentlyContinue
        }
        if (-not (Get-Alias -Name 'git-tower' -ErrorAction SilentlyContinue)) {
            Set-Alias -Name 'git-tower' -Value 'Invoke-GitTower' -ErrorAction SilentlyContinue
        }
        if (-not (Get-Alias -Name 'gitkraken' -ErrorAction SilentlyContinue)) {
            Set-Alias -Name 'gitkraken' -Value 'Invoke-GitKraken' -ErrorAction SilentlyContinue
        }
        if (-not (Get-Alias -Name 'gitbutler' -ErrorAction SilentlyContinue)) {
            Set-Alias -Name 'gitbutler' -Value 'Invoke-GitButler' -ErrorAction SilentlyContinue
        }
        if (-not (Get-Alias -Name 'jj' -ErrorAction SilentlyContinue)) {
            Set-Alias -Name 'jj' -Value 'Invoke-Jujutsu' -ErrorAction SilentlyContinue
        }
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'git-enhanced'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: git-enhanced" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load git-enhanced fragment: $($_.Exception.Message)"
    }
}
