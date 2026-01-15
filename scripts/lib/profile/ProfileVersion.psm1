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
                    $debugLevel = 0
                    if ($gitDir -and -not [string]::IsNullOrWhiteSpace($gitDir) -and (Test-Path -LiteralPath $gitDir)) {
                        # Level 3: Log git directory found
                        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                            Write-Host "  [profile-version.git] Git directory found: $gitDir" -ForegroundColor DarkGray
                        }
                        try {
                            Push-Location $capturedProfileDir -ErrorAction Stop
                            try {
                                $gitOutput = git rev-parse --short HEAD 2>&1
                                if ($LASTEXITCODE -eq 0 -and $gitOutput) {
                                    $global:PSProfileGitCommit = $gitOutput.Trim()
                                    # Level 3: Log successful git commit hash retrieval
                                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                                        Write-Verbose "[profile-version.git] Successfully retrieved commit hash: $global:PSProfileGitCommit"
                                    }
                                }
                                else {
                                    $global:PSProfileGitCommit = 'unknown'
                                    # Level 2: Log git command failure
                                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                                        Write-Verbose "[profile-version.git] Git command failed or returned empty output"
                                    }
                                }
                            }
                            catch {
                                $global:PSProfileGitCommit = 'unknown'
                                # Level 2: Log git command exception
                                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                                    Write-Verbose "[profile-version.git] Git command exception: $($_.Exception.Message)"
                                }
                            }
                            finally {
                                Pop-Location -ErrorAction SilentlyContinue
                            }
                        }
                        catch {
                            $global:PSProfileGitCommit = 'unknown'
                            # Level 2: Log push-location failure
                            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                                Write-Verbose "[profile-version.git] Failed to change directory: $($_.Exception.Message)"
                            }
                        }
                    }
                    else {
                        $global:PSProfileGitCommit = 'unknown'
                        # Level 3: Log git directory not found
                        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                            Write-Host "  [profile-version.git] Git directory not found: $gitDir" -ForegroundColor DarkGray
                        }
                    }
                }
                return $global:PSProfileGitCommit
            }
        }

        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            if ($debugLevel -ge 1) {
                $commitHash = if ($global:PSProfileGitCommitGetter) { & $global:PSProfileGitCommitGetter } else { 'unknown' }
                Write-Verbose "[profile-version.init] PowerShell Profile v$global:PSProfileVersion (commit: $commitHash)"
            }
            # Level 2: Log successful initialization
            if ($debugLevel -ge 2) {
                Write-Verbose "[profile-version.init] Profile version initialized: $global:PSProfileVersion"
            }
            # Level 3: Log detailed initialization information
            if ($debugLevel -ge 3) {
                $commitHash = if ($global:PSProfileGitCommitGetter) { & $global:PSProfileGitCommitGetter } else { 'unknown' }
                Write-Host "  [profile-version.init] Initialization details - Version: $global:PSProfileVersion, Commit: $commitHash, ProfileDir: $ProfileDir" -ForegroundColor DarkGray
            }
        }
    }
}

Export-ModuleMember -Function 'Initialize-ProfileVersion'
