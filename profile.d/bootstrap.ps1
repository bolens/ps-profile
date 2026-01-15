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

        # Load ErrorHandlingStandard (depends on global state, provides standardized error handling)
        $errorHandlingStandardPath = Join-Path $bootstrapModulesDir 'ErrorHandlingStandard.ps1'
        if ($errorHandlingStandardPath -and -not [string]::IsNullOrWhiteSpace($errorHandlingStandardPath) -and (Test-Path -LiteralPath $errorHandlingStandardPath)) {
            try {
                . $errorHandlingStandardPath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (ErrorHandlingStandard.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module ErrorHandlingStandard.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load CloudProviderBase (depends on global state and error handling, provides cloud provider patterns)
        $cloudProviderBasePath = Join-Path $bootstrapModulesDir 'CloudProviderBase.ps1'
        if ($cloudProviderBasePath -and -not [string]::IsNullOrWhiteSpace($cloudProviderBasePath) -and (Test-Path -LiteralPath $cloudProviderBasePath)) {
            try {
                . $cloudProviderBasePath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (CloudProviderBase.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module CloudProviderBase.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load PromptBase (depends on global state and error handling, provides prompt initialization patterns)
        $promptBasePath = Join-Path $bootstrapModulesDir 'PromptBase.ps1'
        if ($promptBasePath -and -not [string]::IsNullOrWhiteSpace($promptBasePath) -and (Test-Path -LiteralPath $promptBasePath)) {
            try {
                . $promptBasePath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (PromptBase.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module PromptBase.ps1 : $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load PackageManagerBase (depends on global state and error handling, provides package manager patterns)
        $packageManagerBasePath = Join-Path $bootstrapModulesDir 'PackageManagerBase.ps1'
        if ($packageManagerBasePath -and -not [string]::IsNullOrWhiteSpace($packageManagerBasePath) -and (Test-Path -LiteralPath $packageManagerBasePath)) {
            try {
                . $packageManagerBasePath
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (PackageManagerBase.ps1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load bootstrap module PackageManagerBase.ps1 : $($_.Exception.Message)"
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

        # Load FragmentCommandRegistry and CommandDispatcher modules (for on-demand fragment loading)
        # These enable automatic fragment loading when commands are called
        $repoRoot = Split-Path -Parent $bootstrapModulesDir
        $fragmentLibDir = Join-Path $repoRoot 'scripts' 'lib' 'fragment'
        
        # Load FragmentCommandRegistry module
        $registryModulePath = Join-Path $fragmentLibDir 'FragmentCommandRegistry.psm1'
        if ($registryModulePath -and -not [string]::IsNullOrWhiteSpace($registryModulePath) -and (Test-Path -LiteralPath $registryModulePath)) {
            try {
                Import-Module $registryModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (FragmentCommandRegistry.psm1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load FragmentCommandRegistry module: $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load FragmentLoader module
        $loaderModulePath = Join-Path $fragmentLibDir 'FragmentLoader.psm1'
        if ($loaderModulePath -and -not [string]::IsNullOrWhiteSpace($loaderModulePath) -and (Test-Path -LiteralPath $loaderModulePath)) {
            try {
                Import-Module $loaderModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (FragmentLoader.psm1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load FragmentLoader module: $($_.Exception.Message)"
                    }
                }
            }
        }

        # Load CommandDispatcher module and register it
        $dispatcherModulePath = Join-Path $fragmentLibDir 'CommandDispatcher.psm1'
        if ($dispatcherModulePath -and -not [string]::IsNullOrWhiteSpace($dispatcherModulePath) -and (Test-Path -LiteralPath $dispatcherModulePath)) {
            try {
                Import-Module $dispatcherModulePath -DisableNameChecking -ErrorAction SilentlyContinue
                # Register the dispatcher if available
                if (Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue) {
                    $null = Register-CommandDispatcher
                }
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                        Write-ProfileError -ErrorRecord $_ -Context "Fragment: bootstrap (CommandDispatcher.psm1)" -Category 'Fragment'
                    }
                    else {
                        Write-Warning "Failed to load CommandDispatcher module: $($_.Exception.Message)"
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
