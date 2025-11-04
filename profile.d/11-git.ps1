# ===============================================
# 11-git.ps1
# Consolidated Git helpers
# ===============================================

# Basic git shortcuts — simple stubs that forward all args to git.
# These are intentionally lightweight; if `git` isn't installed the call will
# fail at runtime. Suppress the positional parameter analyzer for these
# forwarding helpers.

# Git status - show status
if (-not (Test-Path Function:Invoke-GitStatus)) { 
    function Invoke-GitStatus { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a }
    Set-Alias -Name gs -Value Invoke-GitStatus -ErrorAction SilentlyContinue
}
# Git add - stage changes
if (-not (Test-Path Function:Add-GitChanges)) { 
    function Add-GitChanges { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a }
    Set-Alias -Name ga -Value Add-GitChanges -ErrorAction SilentlyContinue
}
# Git commit - commit changes
if (-not (Test-Path Function:Save-GitCommit)) { 
    function Save-GitCommit { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a }
    Set-Alias -Name gc -Value Save-GitCommit -ErrorAction SilentlyContinue
}
# Git push - push to remote
if (-not (Test-Path Function:Publish-GitChanges)) { 
    function Publish-GitChanges { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a }
    Set-Alias -Name gp -Value Publish-GitChanges -ErrorAction SilentlyContinue
}
# Git log - show commit log
if (-not (Test-Path Function:Get-GitLog)) { 
    function Get-GitLog { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a }
    Set-Alias -Name gl -Value Get-GitLog -ErrorAction SilentlyContinue
}
# Git diff - show changes
if (-not (Test-Path Function:Compare-GitChanges)) { 
    function Compare-GitChanges { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a }
    Set-Alias -Name gd -Value Compare-GitChanges -ErrorAction SilentlyContinue
}
# Git branch - manage branches
if (-not (Test-Path Function:Get-GitBranch)) { 
    function Get-GitBranch { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a }
    Set-Alias -Name gb -Value Get-GitBranch -ErrorAction SilentlyContinue
}
# Git checkout - switch branches
if (-not (Test-Path Function:Switch-GitBranch)) { 
    function Switch-GitBranch { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a }
    Set-Alias -Name gco -Value Switch-GitBranch -ErrorAction SilentlyContinue
}
# Git commit with message - commit changes with message
if (-not (Test-Path Function:Save-GitCommitWithMessage)) { 
    function Save-GitCommitWithMessage { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a }
    Set-Alias -Name gcm -Value Save-GitCommitWithMessage -ErrorAction SilentlyContinue
}
# Git pull - pull from remote
if (-not (Test-Path Function:Get-GitChanges)) { 
    function Get-GitChanges { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a }
    Set-Alias -Name gpl -Value Get-GitChanges -ErrorAction SilentlyContinue
}
# Git fetch - fetch from remote
if (-not (Test-Path Function:Receive-GitChanges)) { 
    function Receive-GitChanges { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a }
    Set-Alias -Name gf -Value Receive-GitChanges -ErrorAction SilentlyContinue
}

# Extras: register heavier helpers lazily so dot-sourcing this fragment remains cheap
if (-not (Test-Path Function:Ensure-GitHelper)) {
    <#
    .SYNOPSIS
        Ensures Git helper functions are initialized.
    .DESCRIPTION
        Lazily initializes additional Git helper functions when first called.
        This keeps the initial profile loading fast by deferring heavier Git helpers.
    #>
    function Ensure-GitHelper {
        if ($script:__GitHelpersInitialized) { return }
        $script:__GitHelpersInitialized = $true
        if (-not (Get-Command -Name Set-AgentModeFunction -ErrorAction SilentlyContinue)) { return }
        $null = Set-AgentModeFunction -Name 'Invoke-GitClone' -Body { git clone @args } # Git clone - clone a repository
        Set-Alias -Name gcl -Value Invoke-GitClone -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Save-GitStash' -Body { git stash @args } # Git stash - stash changes
        Set-Alias -Name gsta -Value Save-GitStash -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Restore-GitStash' -Body { git stash pop @args } # Git stash pop - apply stashed changes
        Set-Alias -Name gstp -Value Restore-GitStash -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Merge-GitRebase' -Body { git rebase @args } # Git rebase - rebase commits
        Set-Alias -Name gr -Value Merge-GitRebase -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Continue-GitRebase' -Body { git rebase --continue } # Git rebase continue - continue rebase
        Set-Alias -Name grc -Value Continue-GitRebase -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Update-GitSubmodule' -Body { git submodule update --init --recursive @args } # Git submodule update - update submodules
        Set-Alias -Name gsub -Value Update-GitSubmodule -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Clear-GitUntracked' -Body { git clean -fdx @args } # Git clean - remove untracked files
        Set-Alias -Name gclean -Value Clear-GitUntracked -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Set-LocationGitRoot' -Body { # Git cd to root - change to repository root
            $root = (& git rev-parse --show-toplevel) 2>$null
            if ($LASTEXITCODE -eq 0 -and $root) { Set-Location -LiteralPath $root } else { Write-Warning 'Not inside a git repository' }
        }
        Set-Alias -Name cdg -Value Set-LocationGitRoot -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Switch-GitPreviousBranch' -Body { git checkout - } # Git checkout previous - switch to previous branch
        Set-Alias -Name gob -Value Switch-GitPreviousBranch -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Remove-GitMergedBranches' -Body { # Git prune merged - remove merged branches
            $up = (git rev-parse --abbrev-ref --symbolic-full-name '@{u=}') 2>$null
            if (-not $up) { Write-Warning 'No upstream set for this branch'; return }
            git fetch --prune
            git branch --merged | ForEach-Object {
                $b = $_.Trim().TrimStart('*', ' ')
                if ($b -and $b -notin @('main', 'master', 'develop')) { git branch -D $b 2>$null | Out-Null }
            }
        }
        Set-Alias -Name gprune -Value Remove-GitMergedBranches -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Sync-GitRepository' -Body { git fetch --prune; git rebase '@{u}' } # Git sync - fetch and rebase
        Set-Alias -Name gsync -Value Sync-GitRepository -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Undo-GitCommit' -Body { git reset --soft HEAD~1 } # Git undo - soft reset last commit
        Set-Alias -Name gundo -Value Undo-GitCommit -ErrorAction SilentlyContinue
        $null = Set-AgentModeFunction -Name 'Get-GitDefaultBranch' -Body { # Git default branch - get default branch name
            $b = (git symbolic-ref refs/remotes/origin/HEAD 2>$null) -replace '^refs/remotes/origin/', ''
            if ($b) { $b } else { 'main' }
        }
        Set-Alias -Name gdefault -Value Get-GitDefaultBranch -ErrorAction SilentlyContinue

        # GitHub CLI helpers
        if (Get-Command -Name Test-CachedCommand -ErrorAction SilentlyContinue) {
            $null = Set-AgentModeFunction -Name 'New-GitHubPullRequest' -Body { if (Test-CachedCommand gh) { gh pr create @args } else { Write-Warning 'GitHub CLI (gh) not found' } } # GitHub PR create - create a pull request
            Set-Alias -Name prc -Value New-GitHubPullRequest -ErrorAction SilentlyContinue
            $null = Set-AgentModeFunction -Name 'Show-GitHubPullRequest' -Body { if (Test-CachedCommand gh) { gh pr view --web @args } else { Write-Warning 'GitHub CLI (gh) not found' } } # GitHub PR view - view pull request in browser
            Set-Alias -Name prv -Value Show-GitHubPullRequest -ErrorAction SilentlyContinue
        }
        else {
            $null = Set-AgentModeFunction -Name 'New-GitHubPullRequest' -Body { if (Get-Command gh -ErrorAction SilentlyContinue) { gh pr create @args } else { Write-Warning 'GitHub CLI (gh) not found' } } # GitHub PR create - create a pull request
            Set-Alias -Name prc -Value New-GitHubPullRequest -ErrorAction SilentlyContinue
            $null = Set-AgentModeFunction -Name 'Show-GitHubPullRequest' -Body { if (Get-Command gh -ErrorAction SilentlyContinue) { gh pr view --web @args } else { Write-Warning 'GitHub CLI (gh) not found' } } # GitHub PR view - view pull request in browser
            Set-Alias -Name prv -Value Show-GitHubPullRequest -ErrorAction SilentlyContinue
        }
    }
}

# Register lazy stubs for the heavier Git helpers
# Git clone - clone a repository
if (-not (Test-Path Function:Invoke-GitClone)) { Set-Item -Path Function:Invoke-GitClone -Value { Ensure-GitHelper; & (Get-Command Invoke-GitClone -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gcl -Value Invoke-GitClone -ErrorAction SilentlyContinue }
# Git stash - stash changes
if (-not (Test-Path Function:Save-GitStash)) { Set-Item -Path Function:Save-GitStash -Value { Ensure-GitHelper; & (Get-Command Save-GitStash -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gsta -Value Save-GitStash -ErrorAction SilentlyContinue }
# Git stash pop - apply stashed changes
if (-not (Test-Path Function:Restore-GitStash)) { Set-Item -Path Function:Restore-GitStash -Value { Ensure-GitHelper; & (Get-Command Restore-GitStash -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gstp -Value Restore-GitStash -ErrorAction SilentlyContinue }
# Git rebase - rebase commits
if (-not (Test-Path Function:Merge-GitRebase)) { Set-Item -Path Function:Merge-GitRebase -Value { Ensure-GitHelper; & (Get-Command Merge-GitRebase -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gr -Value Merge-GitRebase -ErrorAction SilentlyContinue }
# Git rebase continue - continue rebase
if (-not (Test-Path Function:Continue-GitRebase)) { Set-Item -Path Function:Continue-GitRebase -Value { Ensure-GitHelper; & (Get-Command Continue-GitRebase -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name grc -Value Continue-GitRebase -ErrorAction SilentlyContinue }
# Git submodule update - update submodules
if (-not (Test-Path Function:Update-GitSubmodule)) { Set-Item -Path Function:Update-GitSubmodule -Value { Ensure-GitHelper; & (Get-Command Update-GitSubmodule -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gsub -Value Update-GitSubmodule -ErrorAction SilentlyContinue }
# Git clean - remove untracked files
if (-not (Test-Path Function:Clear-GitUntracked)) { Set-Item -Path Function:Clear-GitUntracked -Value { Ensure-GitHelper; & (Get-Command Clear-GitUntracked -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gclean -Value Clear-GitUntracked -ErrorAction SilentlyContinue }
# Git cd to root - change to repository root
if (-not (Test-Path Function:Set-LocationGitRoot)) { Set-Item -Path Function:Set-LocationGitRoot -Value { Ensure-GitHelper; & (Get-Command Set-LocationGitRoot -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name cdg -Value Set-LocationGitRoot -ErrorAction SilentlyContinue }
# Git checkout previous - switch to previous branch
if (-not (Test-Path Function:Switch-GitPreviousBranch)) { Set-Item -Path Function:Switch-GitPreviousBranch -Value { Ensure-GitHelper; & (Get-Command Switch-GitPreviousBranch -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gob -Value Switch-GitPreviousBranch -ErrorAction SilentlyContinue }
# Git prune merged - remove merged branches
if (-not (Test-Path Function:Remove-GitMergedBranches)) { Set-Item -Path Function:Remove-GitMergedBranches -Value { Ensure-GitHelper; & (Get-Command Remove-GitMergedBranches -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gprune -Value Remove-GitMergedBranches -ErrorAction SilentlyContinue }
# Git sync - fetch and rebase
if (-not (Test-Path Function:Sync-GitRepository)) { Set-Item -Path Function:Sync-GitRepository -Value { Ensure-GitHelper; & (Get-Command Sync-GitRepository -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gsync -Value Sync-GitRepository -ErrorAction SilentlyContinue }
# Git undo - soft reset last commit
if (-not (Test-Path Function:Undo-GitCommit)) { Set-Item -Path Function:Undo-GitCommit -Value { Ensure-GitHelper; & (Get-Command Undo-GitCommit -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gundo -Value Undo-GitCommit -ErrorAction SilentlyContinue }
# Git default branch - get default branch name
if (-not (Test-Path Function:Get-GitDefaultBranch)) { Set-Item -Path Function:Get-GitDefaultBranch -Value { Ensure-GitHelper; & (Get-Command Get-GitDefaultBranch -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null; Set-Alias -Name gdefault -Value Get-GitDefaultBranch -ErrorAction SilentlyContinue }
