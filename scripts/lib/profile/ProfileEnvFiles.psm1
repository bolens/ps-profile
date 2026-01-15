# ===============================================
# ProfileEnvFiles.psm1
# Environment file loading for profile
# ===============================================

<#
.SYNOPSIS
    Loads .env files early in profile initialization.
.DESCRIPTION
    Loads .env files before checking environment variables so that variables like
    PS_PROFILE_PARALLEL_LOADING can be set in .env files.
.PARAMETER ProfileDir
    Directory containing the profile files.
#>
function Initialize-ProfileEnvFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ProfileDir
    )

    $envFileModule = Join-Path $ProfileDir 'scripts' 'lib' 'utilities' 'EnvFile.psm1'
    $envFileModuleExists = if ($envFileModule -and -not [string]::IsNullOrWhiteSpace($envFileModule)) { 
        Test-Path -LiteralPath $envFileModule 
    } 
    else { 
        $false 
    }
    
    if ($envFileModuleExists) {
        try {
            Import-Module $envFileModule -DisableNameChecking -ErrorAction SilentlyContinue
            if (Get-Command Initialize-EnvFiles -ErrorAction SilentlyContinue) {
                # Use -Overwrite to ensure .env file values override any existing (even empty) environment variables
                Initialize-EnvFiles -RepoRoot $ProfileDir -Overwrite -ErrorAction SilentlyContinue
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                    if ($debugLevel -ge 2) {
                        $envFile = Join-Path $ProfileDir '.env'
                        $envLocalFile = Join-Path $ProfileDir '.env.local'
                        $envExists = Test-Path -LiteralPath $envFile
                        $envLocalExists = Test-Path -LiteralPath $envLocalFile
                        Write-Verbose "[profile-env-files.init] Loaded .env files. .env exists: $envExists, .env.local exists: $envLocalExists"
                    }
                    # Level 3: Log detailed environment file information
                    if ($debugLevel -ge 3) {
                        $envFile = Join-Path $ProfileDir '.env'
                        $envLocalFile = Join-Path $ProfileDir '.env.local'
                        $envExists = Test-Path -LiteralPath $envFile
                        $envLocalExists = Test-Path -LiteralPath $envLocalFile
                        Write-Host "  [profile-env-files.init] Environment file details - ProfileDir: $ProfileDir, .env: $envFile (exists: $envExists), .env.local: $envLocalFile (exists: $envLocalExists)" -ForegroundColor DarkGray
                    }
                }
            }
            else {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                    if ($debugLevel -ge 1) {
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "Initialize-EnvFiles command not found after importing EnvFile module" -OperationName 'profile-env-files.init' -Context @{
                                EnvFileModule = $envFileModule
                            } -Code 'CommandNotFound'
                        }
                        else {
                            Write-Warning "[profile-env-files.init] Initialize-EnvFiles command not found after importing EnvFile module"
                        }
                    }
                    # Level 3: Log detailed module import information
                    if ($debugLevel -ge 3) {
                        Write-Host "  [profile-env-files.init] Module import details - EnvFileModule: $envFileModule, ModuleExists: $envFileModuleExists, Initialize-EnvFilesAvailable: $false" -ForegroundColor DarkGray
                        Write-Host "  [profile-env-files.init] Module imported but Initialize-EnvFiles not available - this is non-critical" -ForegroundColor DarkGray
                    }
                }
                else {
                    Write-Warning "[profile-env-files.init] Initialize-EnvFiles command not found after importing EnvFile module"
                }
            }
        }
        catch {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Failed to load .env files early: $($_.Exception.Message)" -OperationName 'profile-env-files.init' -Context @{
                            # Technical context
                            EnvFileModule = $envFileModule
                            ProfileDir    = $ProfileDir
                            # Error context
                            Error         = $_.Exception.Message
                            ErrorType     = $_.Exception.GetType().FullName
                            # Invocation context
                            FunctionName  = 'Initialize-ProfileEnvFiles'
                        } -Code 'LoadFailed'
                    }
                    else {
                        Write-Warning "[profile-env-files.init] Failed to load .env files early: $($_.Exception.Message)"
                    }
                }
                # Level 3: Log detailed error information
                if ($debugLevel -ge 3) {
                    Write-Host "  [profile-env-files.init] Load error details - EnvFileModule: $envFileModule, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
            else {
                # Always log warnings even if debug is off
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to load .env files early: $($_.Exception.Message)" -OperationName 'profile-env-files.init' -Context @{
                        EnvFileModule = $envFileModule
                        ProfileDir    = $ProfileDir
                        Error         = $_.Exception.Message
                        ErrorType     = $_.Exception.GetType().FullName
                        FunctionName  = 'Initialize-ProfileEnvFiles'
                    } -Code 'LoadFailed'
                }
                else {
                    Write-Warning "[profile-env-files.init] Failed to load .env files early: $($_.Exception.Message)"
                }
            }
        }
    }
    else {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[profile-env-files.init] EnvFile module not found at: $envFileModule"
        }
        # Level 3: Log detailed module path information
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Host "  [profile-env-files.init] Module path details - ProfileDir: $ProfileDir, EnvFileModule: $envFileModule, ModuleExists: $envFileModuleExists" -ForegroundColor DarkGray
        }
    }
}

Export-ModuleMember -Function 'Initialize-ProfileEnvFiles'
