# ===============================================
# bootstrap.ps1
# Core bootstrap helpers for profile fragments
# ===============================================

# Load bootstrap modules in dependency order
# Tier: core
try {
    $bootstrapModulesDir = Join-Path $PSScriptRoot 'bootstrap'

    if ($bootstrapModulesDir -and -not [string]::IsNullOrWhiteSpace($bootstrapModulesDir) -and (Test-Path -LiteralPath $bootstrapModulesDir)) {
        # Load GlobalState first (initializes all global variables)
        $globalStatePath = Join-Path $bootstrapModulesDir 'GlobalState.ps1'
        if ($globalStatePath -and -not [string]::IsNullOrWhiteSpace($globalStatePath) -and (Test-Path -LiteralPath $globalStatePath)) {
            try {
                . $globalStatePath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (GlobalState.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module GlobalState.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load CommandCache (depends on global state)
        $commandCachePath = Join-Path $bootstrapModulesDir 'CommandCache.ps1'
        if ($commandCachePath -and -not [string]::IsNullOrWhiteSpace($commandCachePath) -and (Test-Path -LiteralPath $commandCachePath)) {
            try {
                . $commandCachePath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (CommandCache.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module CommandCache.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load AssumedCommands (depends on global state)
        $assumedCommandsPath = Join-Path $bootstrapModulesDir 'AssumedCommands.ps1'
        if ($assumedCommandsPath -and -not [string]::IsNullOrWhiteSpace($assumedCommandsPath) -and (Test-Path -LiteralPath $assumedCommandsPath)) {
            try {
                . $assumedCommandsPath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (AssumedCommands.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module AssumedCommands.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load MissingToolWarnings (depends on global state)
        $missingToolWarningsPath = Join-Path $bootstrapModulesDir 'MissingToolWarnings.ps1'
        if ($missingToolWarningsPath -and -not [string]::IsNullOrWhiteSpace($missingToolWarningsPath) -and (Test-Path -LiteralPath $missingToolWarningsPath)) {
            try {
                . $missingToolWarningsPath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (MissingToolWarnings.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module MissingToolWarnings.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load BatchLoadingSummary (depends on global state)
        $batchLoadingSummaryPath = Join-Path $bootstrapModulesDir 'BatchLoadingSummary.ps1'
        if ($batchLoadingSummaryPath -and -not [string]::IsNullOrWhiteSpace($batchLoadingSummaryPath) -and (Test-Path -LiteralPath $batchLoadingSummaryPath)) {
            try {
                . $batchLoadingSummaryPath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (BatchLoadingSummary.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module BatchLoadingSummary.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load SafeTestPath wrapper (handles null/empty paths gracefully)
        $safeTestPathPath = Join-Path $bootstrapModulesDir 'SafeTestPath.ps1'
        if ($safeTestPathPath -and -not [string]::IsNullOrWhiteSpace($safeTestPathPath) -and (Test-Path -LiteralPath $safeTestPathPath)) {
            try {
                . $safeTestPathPath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (SafeTestPath.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module SafeTestPath.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load FragmentWarnings (depends on global state)
        $fragmentWarningsPath = Join-Path $bootstrapModulesDir 'FragmentWarnings.ps1'
        if ($fragmentWarningsPath -and -not [string]::IsNullOrWhiteSpace($fragmentWarningsPath) -and (Test-Path -LiteralPath $fragmentWarningsPath)) {
            try {
                . $fragmentWarningsPath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (FragmentWarnings.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module FragmentWarnings.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load FunctionRegistration (depends on global state)
        $functionRegistrationPath = Join-Path $bootstrapModulesDir 'FunctionRegistration.ps1'
        if ($functionRegistrationPath -and -not [string]::IsNullOrWhiteSpace($functionRegistrationPath) -and (Test-Path -LiteralPath $functionRegistrationPath)) {
            try {
                . $functionRegistrationPath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (FunctionRegistration.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module FunctionRegistration.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load ModulePathCache (path caching utilities, used by ModuleLoading)
        $modulePathCachePath = Join-Path $bootstrapModulesDir 'ModulePathCache.ps1'
        if ($modulePathCachePath -and -not [string]::IsNullOrWhiteSpace($modulePathCachePath) -and (Test-Path -LiteralPath $modulePathCachePath)) {
            try {
                . $modulePathCachePath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (ModulePathCache.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module ModulePathCache.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load ModuleLoading (standardized module loading, depends on ModulePathCache)
        $moduleLoadingPath = Join-Path $bootstrapModulesDir 'ModuleLoading.ps1'
        if ($moduleLoadingPath -and -not [string]::IsNullOrWhiteSpace($moduleLoadingPath) -and (Test-Path -LiteralPath $moduleLoadingPath)) {
            try {
                . $moduleLoadingPath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (ModuleLoading.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module ModuleLoading.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load UserHome (standalone utility)
        $userHomePath = Join-Path $bootstrapModulesDir 'UserHome.ps1'
        if ($userHomePath -and -not [string]::IsNullOrWhiteSpace($userHomePath) -and (Test-Path -LiteralPath $userHomePath)) {
            try {
                . $userHomePath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (UserHome.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module UserHome.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load bootstrap fragment: $($_.Exception.Message)"
        }
    }
}
