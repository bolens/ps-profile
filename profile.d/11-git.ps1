# ===============================================
# 11-git.ps1
# Consolidated Git helpers
# ===============================================

# Basic git shortcuts — simple stubs that forward all args to git.
# These are intentionally lightweight; if `git` isn't installed the call will
# fail at runtime. Suppress the positional parameter analyzer for these
# forwarding helpers.

# Git status - show status
if (-not (Test-Path Function:gs)) { Set-Item -Path Function:gs -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a } -Force | Out-Null }
# Git add - stage changes
if (-not (Test-Path Function:ga)) { Set-Item -Path Function:ga -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a } -Force | Out-Null }
# Git commit - commit changes
if (-not (Test-Path Function:gc)) { Set-Item -Path Function:gc -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a } -Force | Out-Null }
# Git push - push to remote
if (-not (Test-Path Function:gp)) { Set-Item -Path Function:gp -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a } -Force | Out-Null }
# Git log - show commit log
if (-not (Test-Path Function:gl)) { Set-Item -Path Function:gl -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a } -Force | Out-Null }
# Git diff - show changes
if (-not (Test-Path Function:gd)) { Set-Item -Path Function:gd -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a } -Force | Out-Null }
# Git branch - manage branches
if (-not (Test-Path Function:gb)) { Set-Item -Path Function:gb -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a } -Force | Out-Null }
# Git checkout - switch branches
if (-not (Test-Path Function:gco)) { Set-Item -Path Function:gco -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a } -Force | Out-Null }
# Git commit with message - commit changes with message
if (-not (Test-Path Function:gcm)) { Set-Item -Path Function:gcm -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a } -Force | Out-Null }
# Git pull - pull from remote
if (-not (Test-Path Function:gpl)) { Set-Item -Path Function:gpl -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a } -Force | Out-Null }
# Git fetch - fetch from remote
if (-not (Test-Path Function:gf)) { Set-Item -Path Function:gf -Value { param([Parameter(ValueFromRemainingArguments = $true)] $a) git @a } -Force | Out-Null }

# Extras: register heavier helpers lazily so dot-sourcing this fragment remains cheap
if (-not (Test-Path Function:Ensure-GitHelper)) {
    function Ensure-GitHelper {
        if ($script:__GitHelpersInitialized) { return }
        $script:__GitHelpersInitialized = $true
        if (-not (Get-Command -Name Set-AgentModeFunction -ErrorAction SilentlyContinue)) { return }
        $null = Set-AgentModeFunction -Name 'gcl' -Body { git clone @args } # Git clone - clone a repository
        $null = Set-AgentModeFunction -Name 'gsta' -Body { git stash @args } # Git stash - stash changes
        $null = Set-AgentModeFunction -Name 'gstp' -Body { git stash pop @args } # Git stash pop - apply stashed changes
        $null = Set-AgentModeFunction -Name 'gr' -Body { git rebase @args } # Git rebase - rebase commits
        $null = Set-AgentModeFunction -Name 'grc' -Body { git rebase --continue } # Git rebase continue - continue rebase
        $null = Set-AgentModeFunction -Name 'gsub' -Body { git submodule update --init --recursive @args } # Git submodule update - update submodules
        $null = Set-AgentModeFunction -Name 'gclean' -Body { git clean -fdx @args } # Git clean - remove untracked files
        $null = Set-AgentModeFunction -Name 'cdg' -Body { # Git cd to root - change to repository root
            $root = (& git rev-parse --show-toplevel) 2>$null
            if ($LASTEXITCODE -eq 0 -and $root) { Set-Location -LiteralPath $root } else { Write-Warning 'Not inside a git repository' }
        }
        $null = Set-AgentModeFunction -Name 'gob' -Body { git checkout - } # Git checkout previous - switch to previous branch
        $null = Set-AgentModeFunction -Name 'gprune' -Body { # Git prune merged - remove merged branches
            $up = (git rev-parse --abbrev-ref --symbolic-full-name '@{u=}') 2>$null
            if (-not $up) { Write-Warning 'No upstream set for this branch'; return }
            git fetch --prune
            git branch --merged | ForEach-Object {
                $b = $_.Trim().TrimStart('*', ' ')
                if ($b -and $b -notin @('main', 'master', 'develop')) { git branch -D $b 2>$null | Out-Null }
            }
        }
        $null = Set-AgentModeFunction -Name 'gsync' -Body { git fetch --prune; git rebase '@{u}' } # Git sync - fetch and rebase
        $null = Set-AgentModeFunction -Name 'gundo' -Body { git reset --soft HEAD~1 } # Git undo - soft reset last commit
        $null = Set-AgentModeFunction -Name 'gdefault' -Body { # Git default branch - get default branch name
            $b = (git symbolic-ref refs/remotes/origin/HEAD 2>$null) -replace '^refs/remotes/origin/', ''
            if ($b) { $b } else { 'main' }
        }

        # GitHub CLI helpers
        if (Get-Command -Name Test-CachedCommand -ErrorAction SilentlyContinue) {
            $null = Set-AgentModeFunction -Name 'prc' -Body { if (Test-CachedCommand gh) { gh pr create @args } else { Write-Warning 'GitHub CLI (gh) not found' } } # GitHub PR create - create a pull request
            $null = Set-AgentModeFunction -Name 'prv' -Body { if (Test-CachedCommand gh) { gh pr view --web @args } else { Write-Warning 'GitHub CLI (gh) not found' } } # GitHub PR view - view pull request in browser
        }
        else {
            $null = Set-AgentModeFunction -Name 'prc' -Body { if (Get-Command gh -ErrorAction SilentlyContinue) { gh pr create @args } else { Write-Warning 'GitHub CLI (gh) not found' } } # GitHub PR create - create a pull request
            $null = Set-AgentModeFunction -Name 'prv' -Body { if (Get-Command gh -ErrorAction SilentlyContinue) { gh pr view --web @args } else { Write-Warning 'GitHub CLI (gh) not found' } } # GitHub PR view - view pull request in browser
        }
    }
}

# Register lazy stubs for the heavier Git helpers
# Git clone - clone a repository
if (-not (Test-Path Function:gcl)) { Set-Item -Path Function:gcl -Value { Ensure-GitHelper; & (Get-Command gcl -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null }
# Git stash - stash changes
if (-not (Test-Path Function:gsta)) { Set-Item -Path Function:gsta -Value { Ensure-GitHelper; & (Get-Command gsta -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null }
# Git stash pop - apply stashed changes
if (-not (Test-Path Function:gstp)) { Set-Item -Path Function:gstp -Value { Ensure-GitHelper; & (Get-Command gstp -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null }
# Git rebase - rebase commits
if (-not (Test-Path Function:gr)) { Set-Item -Path Function:gr -Value { Ensure-GitHelper; & (Get-Command gr -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null }
# Git rebase continue - continue rebase
if (-not (Test-Path Function:grc)) { Set-Item -Path Function:grc -Value { Ensure-GitHelper; & (Get-Command grc -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null }
# Git submodule update - update submodules
if (-not (Test-Path Function:gsub)) { Set-Item -Path Function:gsub -Value { Ensure-GitHelper; & (Get-Command gsub -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null }
# Git clean - remove untracked files
if (-not (Test-Path Function:gclean)) { Set-Item -Path Function:gclean -Value { Ensure-GitHelper; & (Get-Command gclean -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null }
# Git cd to root - change to repository root
if (-not (Test-Path Function:cdg)) { Set-Item -Path Function:cdg -Value { Ensure-GitHelper; & (Get-Command cdg -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null }
# Git checkout previous - switch to previous branch
if (-not (Test-Path Function:gob)) { Set-Item -Path Function:gob -Value { Ensure-GitHelper; & (Get-Command gob -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null }
# Git prune merged - remove merged branches
if (-not (Test-Path Function:gprune)) { Set-Item -Path Function:gprune -Value { Ensure-GitHelper; & (Get-Command gprune -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null }
# Git sync - fetch and rebase
if (-not (Test-Path Function:gsync)) { Set-Item -Path Function:gsync -Value { Ensure-GitHelper; & (Get-Command gsync -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null }
# Git undo - soft reset last commit
if (-not (Test-Path Function:gundo)) { Set-Item -Path Function:gundo -Value { Ensure-GitHelper; & (Get-Command gundo -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null }
# Git default branch - get default branch name
if (-not (Test-Path Function:gdefault)) { Set-Item -Path Function:gdefault -Value { Ensure-GitHelper; & (Get-Command gdefault -CommandType Function).ScriptBlock.InvokeReturnAsIs($args) } -Force | Out-Null }








