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
                Initialize-EnvFiles -RepoRoot $ProfileDir -ErrorAction SilentlyContinue
                if ($env:PS_PROFILE_DEBUG) {
                    $envFile = Join-Path $ProfileDir '.env'
                    $envLocalFile = Join-Path $ProfileDir '.env.local'
                    $envExists = Test-Path -LiteralPath $envFile
                    $envLocalExists = Test-Path -LiteralPath $envLocalFile
                    Write-Host "Loaded .env files. .env exists: $envExists, .env.local exists: $envLocalExists" -ForegroundColor Gray
                }
            }
            else {
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Host "Initialize-EnvFiles command not found after importing EnvFile module" -ForegroundColor Yellow
                }
            }
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "Failed to load .env files early: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    else {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "EnvFile module not found at: $envFileModule" -ForegroundColor Gray
        }
    }
}

Export-ModuleMember -Function 'Initialize-ProfileEnvFiles'
