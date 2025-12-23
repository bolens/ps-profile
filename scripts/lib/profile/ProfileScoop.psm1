# ===============================================
# ProfileScoop.psm1
# Scoop package manager integration
# ===============================================

<#
.SYNOPSIS
    Initializes Scoop integration for the profile.
.DESCRIPTION
    Detects and configures Scoop package manager if installed.
    Uses ScoopDetection module if available, falls back to legacy detection.
.PARAMETER ProfileDir
    Directory containing the profile files.
#>
function Initialize-ProfileScoop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProfileDir
    )

    $scoopDetectionModule = Join-Path $ProfileDir 'scripts' 'lib' 'runtime' 'ScoopDetection.psm1'
    $scoopDetectionModuleExists = if ($scoopDetectionModule -and -not [string]::IsNullOrWhiteSpace($scoopDetectionModule)) { 
        Test-Path -LiteralPath $scoopDetectionModule 
    } 
    else { 
        $false 
    }
    
    if ($scoopDetectionModuleExists) {
        try {
            Import-Module $scoopDetectionModule -ErrorAction SilentlyContinue -DisableNameChecking
            if (Get-Command Get-ScoopRoot -ErrorAction SilentlyContinue) {
                try {
                    $scoopRoot = Get-ScoopRoot
                    if ($scoopRoot) {
                        # Import Scoop tab completion if available
                        if (Get-Command Get-ScoopCompletionPath -ErrorAction SilentlyContinue) {
                            try {
                                $scoopCompletion = Get-ScoopCompletionPath -ScoopRoot $scoopRoot
                                if ($scoopCompletion -and -not [string]::IsNullOrWhiteSpace($scoopCompletion) -and (Test-Path -LiteralPath $scoopCompletion -ErrorAction SilentlyContinue)) {
                                    Import-Module $scoopCompletion -ErrorAction SilentlyContinue
                                }
                            }
                            catch {
                                if ($env:PS_PROFILE_DEBUG) {
                                    Write-Verbose "Failed to get Scoop completion path: $($_.Exception.Message)"
                                }
                            }
                        }
                        # Add Scoop shims and bin directories to PATH
                        if (Get-Command Add-ScoopToPath -ErrorAction SilentlyContinue) {
                            try {
                                Add-ScoopToPath -ScoopRoot $scoopRoot | Out-Null
                            }
                            catch {
                                if ($env:PS_PROFILE_DEBUG) {
                                    Write-Verbose "Failed to add Scoop to PATH: $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Verbose "Failed to get Scoop root: $($_.Exception.Message)"
                    }
                    # Re-throw to trigger fallback to legacy detection
                    throw
                }
            }
            else {
                throw "Get-ScoopRoot command not available after module import"
            }
        }
        catch {
            # Fallback to legacy detection if module fails (checks common Scoop installation paths)
            if ($env:PS_PROFILE_DEBUG) {
                Write-Verbose "ScoopDetection module failed, using legacy detection: $($_.Exception.Message)"
            }
            Initialize-ProfileScoopLegacy
        }
    }
    else {
        # Try legacy detection if module doesn't exist
        Initialize-ProfileScoopLegacy
    }
}

<#
.SYNOPSIS
    Legacy Scoop detection using common installation paths.
.DESCRIPTION
    Checks common Scoop installation paths as a fallback.
#>
function Initialize-ProfileScoopLegacy {
    [CmdletBinding()]
    param()

    try {
        $scoopRoot = $null
        # Check global Scoop installation first (optimize: check env var before Test-Path)
        if ($env:SCOOP_GLOBAL) {
            if ($env:SCOOP_GLOBAL -and -not [string]::IsNullOrWhiteSpace($env:SCOOP_GLOBAL) -and (Test-Path -LiteralPath $env:SCOOP_GLOBAL -ErrorAction SilentlyContinue)) {
                $scoopRoot = $env:SCOOP_GLOBAL
            }
        }
        # Check local Scoop installation
        if (-not $scoopRoot -and $env:SCOOP) {
            if ($env:SCOOP -and -not [string]::IsNullOrWhiteSpace($env:SCOOP) -and (Test-Path -LiteralPath $env:SCOOP -ErrorAction SilentlyContinue)) {
                $scoopRoot = $env:SCOOP
            }
        }
        if (-not $scoopRoot) {
            $userScoopPath = "$env:USERPROFILE\scoop"
            if ($userScoopPath -and -not [string]::IsNullOrWhiteSpace($userScoopPath) -and (Test-Path -LiteralPath $userScoopPath -ErrorAction SilentlyContinue)) {
                $scoopRoot = $userScoopPath
            }
        }
        if (-not $scoopRoot) {
            $aScoopPath = "A:\scoop"
            if ($aScoopPath -and -not [string]::IsNullOrWhiteSpace($aScoopPath) -and (Test-Path -LiteralPath $aScoopPath -ErrorAction SilentlyContinue)) {
                $scoopRoot = $aScoopPath
            }
        }
        if ($scoopRoot) {
            $scoopCompletion = Join-Path $scoopRoot 'apps\scoop\current\supporting\completion\Scoop-Completion.psd1'
            $scoopCompletionExists = if ($scoopCompletion -and -not [string]::IsNullOrWhiteSpace($scoopCompletion)) { 
                Test-Path -LiteralPath $scoopCompletion -ErrorAction SilentlyContinue 
            } 
            else { 
                $false 
            }
            if ($scoopCompletionExists) {
                Import-Module $scoopCompletion -ErrorAction SilentlyContinue
            }
            # Add Scoop directories to PATH (avoid duplicates)
            $scoopShims = Join-Path $scoopRoot 'shims'
            $scoopBin = Join-Path $scoopRoot 'bin'
            $pathSeparator = [System.IO.Path]::PathSeparator
            $scoopShimsExists = if ($scoopShims -and -not [string]::IsNullOrWhiteSpace($scoopShims)) { 
                Test-Path -LiteralPath $scoopShims -ErrorAction SilentlyContinue 
            } 
            else { 
                $false 
            }
            if ($scoopShimsExists) {
                if ($env:PATH -notlike "*$([regex]::Escape($scoopShims))*") {
                    $env:PATH = "$scoopShims$pathSeparator$env:PATH"
                }
            }
            $scoopBinExists = if ($scoopBin -and -not [string]::IsNullOrWhiteSpace($scoopBin)) { 
                Test-Path -LiteralPath $scoopBin -ErrorAction SilentlyContinue 
            } 
            else { 
                $false 
            }
            if ($scoopBinExists) {
                if ($env:PATH -notlike "*$([regex]::Escape($scoopBin))*") {
                    $env:PATH = "$scoopBin$pathSeparator$env:PATH"
                }
            }
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Verbose "Legacy Scoop detection also failed: $($_.Exception.Message)"
        }
    }
}

Export-ModuleMember -Function 'Initialize-ProfileScoop', 'Initialize-ProfileScoopLegacy'
