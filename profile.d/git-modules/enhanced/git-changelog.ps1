# ===============================================
# git-changelog.ps1
# Git changelog helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env, git
<#
.SYNOPSIS
    Git changelog helpers
.DESCRIPTION
    New-GitChangelog via git-cliff.
.NOTES
    Loaded by git-enhanced.ps1 or directly.
#>
try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'git-changelog') { return }
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
    

    .OUTPUTS
        System.String. Path to the generated changelog file.

    .EXAMPLE
    New-GitChangelog -OutputPath ./output.file -ConfigPath 'value'
        Generates a changelog in the current directory.
    

    .EXAMPLE
        New-GitChangelog -OutputPath "docs/CHANGELOG.md" -Latest
        
        Generates a changelog for the latest tag and saves it to docs/CHANGELOG.md.
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
            Invoke-MissingToolWarning -ToolName 'git-cliff'
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

        # Use standardized error handling if available
        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName "git.changelog.generate" -Context @{
                output_path = $OutputPath
                config_path = $ConfigPath
                tag         = $Tag
                latest      = $Latest.IsPresent
            } -ScriptBlock {
                & git-cliff $arguments
                if ($LASTEXITCODE -eq 0) {
                    return $OutputPath
                }
                else {
                    throw "Failed to generate changelog. Exit code: $LASTEXITCODE"
                }
            }
        }
        else {
            # Fallback to original implementation
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
    }

    if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
        Set-AgentModeAlias -Name 'git-cliff' -Target 'New-GitChangelog'
    }

    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'git-changelog'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'git-changelog' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load git-changelog: "
    }
}
