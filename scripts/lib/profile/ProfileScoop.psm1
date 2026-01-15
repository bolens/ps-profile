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
                                $debugLevel = 0
                                $hasDebug = $false
                                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                                    $hasDebug = $debugLevel -ge 1
                                }
                                
                                if ($hasDebug -and $debugLevel -ge 2) {
                                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                                        Write-StructuredWarning -Message "Failed to get Scoop completion path" -OperationName 'profile-scoop.init' -Context @{
                                            ScoopRoot = $scoopRoot
                                            Error     = $_.Exception.Message
                                            ErrorType = $_.Exception.GetType().FullName
                                        } -Code 'CompletionPathFailed'
                                    }
                                    else {
                                        Write-Verbose "[profile-scoop.init] Failed to get Scoop completion path: $($_.Exception.Message)"
                                    }
                                }
                                # Level 3: Log detailed error information
                                if ($hasDebug -and $debugLevel -ge 3) {
                                    Write-Host "  [profile-scoop.init] Completion path error details - ScoopRoot: $scoopRoot, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                                }
                            }
                        }
                        # Add Scoop shims and bin directories to PATH
                        if (Get-Command Add-ScoopToPath -ErrorAction SilentlyContinue) {
                            try {
                                Add-ScoopToPath -ScoopRoot $scoopRoot | Out-Null
                            }
                            catch {
                                $debugLevel = 0
                                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                                    Write-Verbose "[profile-scoop.init] Failed to add Scoop to PATH: $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                }
                catch {
                    $debugLevel = 0
                    $hasDebug = $false
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                        $hasDebug = $debugLevel -ge 1
                    }
                    
                    if ($hasDebug -and $debugLevel -ge 2) {
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "Failed to get Scoop root" -OperationName 'profile-scoop.init' -Context @{
                                ScoopDetectionModule = $scoopDetectionModule
                                Error                = $_.Exception.Message
                                ErrorType            = $_.Exception.GetType().FullName
                            } -Code 'ScoopRootFailed'
                        }
                        else {
                            Write-Verbose "[profile-scoop.init] Failed to get Scoop root: $($_.Exception.Message)"
                        }
                    }
                    # Level 3: Log detailed error information
                    if ($hasDebug -and $debugLevel -ge 3) {
                        Write-Host "  [profile-scoop.init] Scoop root error details - ScoopDetectionModule: $scoopDetectionModule, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
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
            $debugLevel = 0
            $hasDebug = $false
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                $hasDebug = $debugLevel -ge 1
            }
            
            if ($hasDebug -and $debugLevel -ge 2) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "ScoopDetection module failed, using legacy detection" -OperationName 'profile-scoop.init' -Context @{
                        ScoopDetectionModule = $scoopDetectionModule
                        Error                = $_.Exception.Message
                        ErrorType            = $_.Exception.GetType().FullName
                    } -Code 'ModuleFailed'
                }
                else {
                    Write-Verbose "[profile-scoop.init] ScoopDetection module failed, using legacy detection: $($_.Exception.Message)"
                }
            }
            # Level 3: Log detailed error information
            if ($hasDebug -and $debugLevel -ge 3) {
                Write-Host "  [profile-scoop.init] Module failure details - ScoopDetectionModule: $scoopDetectionModule, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
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
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            $debugLevel = 0
            $hasDebug = $false
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                $hasDebug = $debugLevel -ge 1
            }
            
            if ($hasDebug -and $debugLevel -ge 2) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Legacy Scoop detection also failed" -OperationName 'profile-scoop.legacy' -Context @{
                        Error     = $_.Exception.Message
                        ErrorType = $_.Exception.GetType().FullName
                    } -Code 'LegacyDetectionFailed'
                }
                else {
                    Write-Verbose "[profile-scoop.legacy] Legacy Scoop detection also failed: $($_.Exception.Message)"
                }
            }
            # Level 3: Log detailed error information
            if ($hasDebug -and $debugLevel -ge 3) {
                Write-Host "  [profile-scoop.legacy] Legacy detection error details - Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
        }
    }
}

Export-ModuleMember -Function 'Initialize-ProfileScoop', 'Initialize-ProfileScoopLegacy'
