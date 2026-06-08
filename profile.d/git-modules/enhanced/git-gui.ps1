# ===============================================
# git-gui.ps1
# Git GUI tool launchers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env, git
<#
.SYNOPSIS
    Git GUI tool launchers
.DESCRIPTION
    Tower, Kraken, GitButler, and Jujutsu helpers.
.NOTES
    Loaded by git-enhanced.ps1 or directly.
#>
try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'git-gui') { return }
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
    Invoke-GitTower @('--help')
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
            Invoke-MissingToolWarning -ToolName 'git-tower'
            return
        }

        # Use standardized error handling if available
        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName "git.tower.launch" -Context @{
                repository_path = $RepositoryPath
            } -ScriptBlock {
                Start-Process -FilePath 'git-tower' -ArgumentList $RepositoryPath -ErrorAction Stop
            }
        }
        else {
            # Fallback to original implementation
            try {
                Start-Process -FilePath 'git-tower' -ArgumentList $RepositoryPath -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch Git Tower: $_"
            }
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
    Invoke-GitKraken @('--help')
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
            Invoke-MissingToolWarning -ToolName 'gitkraken'
            return
        }

        # Use standardized error handling if available
        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName "git.gitkraken.launch" -Context @{
                repository_path = $RepositoryPath
            } -ScriptBlock {
                Start-Process -FilePath 'gitkraken' -ArgumentList $RepositoryPath -ErrorAction Stop
            }
        }
        else {
            # Fallback to original implementation
            try {
                Start-Process -FilePath 'gitkraken' -ArgumentList $RepositoryPath -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch GitKraken: $_"
            }
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
    

    .OUTPUTS
        System.String. Output from Git Butler command.

    .EXAMPLE
        Invoke-GitButler status
        
        Shows Git Butler status.
    

    .EXAMPLE
        Invoke-GitButler sync
        
        Syncs the repository with Git Butler.
    #>
    function Invoke-GitButler {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        $gitbutlerCmd = if (Test-CachedCommand 'gitbutler') { Get-CachedExternalCommand 'gitbutler' } else { $null }
        if (-not $gitbutlerCmd) {
            Invoke-MissingToolWarning -ToolName 'gitbutler-nightly' -Tool 'gitbutler'
            return
        }

        # Use standardized error handling if available
        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName "git.gitbutler.invoke" -Context @{
                arguments = $Arguments -join ' '
            } -ScriptBlock {
                if ($Arguments) {
                    & $gitbutlerCmd $Arguments
                }
                else {
                    & $gitbutlerCmd
                }
            }
        }
        else {
            # Fallback to original implementation
            try {
                if ($Arguments) {
                    & $gitbutlerCmd $Arguments
                }
                else {
                    & $gitbutlerCmd
                }
            }
            catch {
                Write-Error "Failed to run gitbutler: $_"
            }
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
    

    .OUTPUTS
        System.String. Output from Jujutsu command.

    .EXAMPLE
        Invoke-Jujutsu init
        
        Initializes a new Jujutsu repository.
    

    .EXAMPLE
        Invoke-Jujutsu status
        
        Shows Jujutsu repository status.
    #>
    function Invoke-Jujutsu {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        $jjCmd = if (Test-CachedCommand 'jj') { Get-CachedExternalCommand 'jj' } else { $null }
        if (-not $jjCmd) {
            Invoke-MissingToolWarning -ToolName 'jj'
            return
        }

        # Use standardized error handling if available
        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName "git.jujutsu.invoke" -Context @{
                arguments = $Arguments -join ' '
            } -ScriptBlock {
                if ($Arguments) {
                    & $jjCmd $Arguments
                }
                else {
                    & $jjCmd
                }
            }
        }
        else {
            # Fallback to original implementation
            try {
                if ($Arguments) {
                    & $jjCmd $Arguments
                }
                else {
                    & $jjCmd
                }
            }
            catch {
                Write-Error "Failed to run jj: $_"
            }
        }
    }

    if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
        Set-AgentModeAlias -Name 'git-tower' -Target 'Invoke-GitTower'
        Set-AgentModeAlias -Name 'gitkraken' -Target 'Invoke-GitKraken'
        Set-AgentModeAlias -Name 'gitbutler' -Target 'Invoke-GitButler'
        Set-AgentModeAlias -Name 'jj' -Target 'Invoke-Jujutsu'
    }

    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'git-gui'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'git-gui' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load git-gui: "
    }
}
