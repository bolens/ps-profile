# ===============================================
# ProfileVersion.psm1
# Profile version and git commit tracking
# ===============================================

<#
.SYNOPSIS
    Initializes profile version information.
.DESCRIPTION
    Sets up profile version and lazy git commit hash calculation.
    Git commit hash is calculated on first access to avoid blocking startup.
.PARAMETER ProfileDir
    Directory containing the profile files.
.PARAMETER ProfileVersion
    Version string for the profile (default: '1.0.0').
#>
function Initialize-ProfileVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfileDir,
        
        [string]$ProfileVersion = '1.0.0'
    )

    if (-not $global:PSProfileVersion) {
        $global:PSProfileVersion = $ProfileVersion
        
        # Defer git commit hash calculation to avoid blocking startup
        # It will be calculated on first access via a lazy property
        $global:PSProfileGitCommit = $null
        $global:PSProfileGitCommitCalculated = $false
        
        # Capture profileDir in closure for lazy getter
        $capturedProfileDir = $ProfileDir
        
        # Lazy getter function for git commit hash
        if (-not (Get-Variable -Name 'PSProfileGitCommitGetter' -Scope Global -ErrorAction SilentlyContinue)) {
            $global:PSProfileGitCommitGetter = {
                if (-not $global:PSProfileGitCommitCalculated) {
                    $global:PSProfileGitCommitCalculated = $true
                    
                    # Quick check: only attempt if .git directory exists
                    $gitDir = Join-Path $capturedProfileDir '.git'
                    if ($gitDir -and -not [string]::IsNullOrWhiteSpace($gitDir) -and (Test-Path -LiteralPath $gitDir)) {
                        try {
                            Push-Location $capturedProfileDir -ErrorAction Stop
                            try {
                                $gitOutput = git rev-parse --short HEAD 2>&1
                                if ($LASTEXITCODE -eq 0 -and $gitOutput) {
                                    $global:PSProfileGitCommit = $gitOutput.Trim()
                                }
                                else {
                                    $global:PSProfileGitCommit = 'unknown'
                                }
                            }
                            catch {
                                $global:PSProfileGitCommit = 'unknown'
                            }
                            finally {
                                Pop-Location -ErrorAction SilentlyContinue
                            }
                        }
                        catch {
                            $global:PSProfileGitCommit = 'unknown'
                        }
                    }
                    else {
                        $global:PSProfileGitCommit = 'unknown'
                    }
                }
                return $global:PSProfileGitCommit
            }
        }

        if ($env:PS_PROFILE_DEBUG) {
            $commitHash = if ($global:PSProfileGitCommitGetter) { & $global:PSProfileGitCommitGetter } else { 'unknown' }
            Write-Host "PowerShell Profile v$global:PSProfileVersion (commit: $commitHash)" -ForegroundColor Cyan
        }
    }
}

Export-ModuleMember -Function 'Initialize-ProfileVersion'
