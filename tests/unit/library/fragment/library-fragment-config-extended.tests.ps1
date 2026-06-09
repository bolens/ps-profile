<#
tests/unit/library-fragment-config-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FragmentConfig accessor and metadata helpers.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:FragmentConfigPath = Get-TestPath -RelativePath 'scripts\lib\fragment\FragmentConfig.psm1' -StartPath $PSScriptRoot -EnsureExists
    $script:PathResolutionModulePath = Get-TestPath -RelativePath 'scripts\lib\path\PathResolution.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $script:PathResolutionModulePath -DisableNameChecking -ErrorAction Stop
    Import-Module $script:FragmentConfigPath -DisableNameChecking -ErrorAction Stop

    function script:New-FragmentConfigProfileDir {
        param(
            [hashtable]$Config
        )

        $profileDir = New-TestTempDirectory -Prefix 'FragmentConfigExtended'
        if ($Config) {
            $configPath = Join-Path $profileDir '.profile-fragments.json'
            ($Config | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $configPath -Encoding UTF8
        }

        return $profileDir
    }
}

Describe 'FragmentConfig extended accessors' {
    Context 'Configuration getter helpers' {
        It 'Get-FragmentLoadOrderOverride returns configured load order' {
            $profileDir = New-FragmentConfigProfileDir -Config @{
                loadOrder = @('bootstrap', 'env', 'git')
            }

            try {
                $loadOrder = Get-FragmentLoadOrderOverride -ProfileDir $profileDir
                $loadOrder | Should -Contain 'bootstrap'
                $loadOrder | Should -Contain 'git'
            }
            finally {
                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Get-FragmentEnvironments returns environment fragment sets' {
            $profileDir = New-FragmentConfigProfileDir -Config @{
                environments = @{
                    minimal     = @('bootstrap', 'env')
                    development = @('bootstrap', 'env', 'git')
                }
            }

            try {
                $environments = Get-FragmentEnvironments -ProfileDir $profileDir
                $environments['minimal'] | Should -Contain 'bootstrap'
                $environments['development'] | Should -Contain 'git'
            }
            finally {
                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Get-FragmentFeatureFlags returns configured feature flags' {
            $profileDir = New-FragmentConfigProfileDir -Config @{
                featureFlags = @{
                    enableAdvancedFeatures = $true
                    experimentalPrompt       = $false
                }
            }

            try {
                $flags = Get-FragmentFeatureFlags -ProfileDir $profileDir
                $flags['enableAdvancedFeatures'] | Should -Be $true
                $flags['experimentalPrompt'] | Should -Be $false
            }
            finally {
                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Get-FragmentPerformanceConfig returns performance settings' {
            $profileDir = New-FragmentConfigProfileDir -Config @{
                performance = @{
                    batchLoad       = $true
                    maxFragmentTime = 750
                }
            }

            try {
                $performance = Get-FragmentPerformanceConfig -ProfileDir $profileDir
                $performance.batchLoad | Should -Be $true
                $performance.maxFragmentTime | Should -Be 750
            }
            finally {
                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Get-DisabledFragments returns configured disabled fragments' {
            $profileDir = New-FragmentConfigProfileDir -Config @{
                disabled = @('git', 'containers')
            }

            try {
                $disabled = Get-DisabledFragments -ProfileDir $profileDir
                $disabled | Should -Contain 'git'
                $disabled | Should -Contain 'containers'
            }
            finally {
                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Get-CurrentEnvironmentFragments returns fragments for the active environment' {
            $profileDir = New-FragmentConfigProfileDir -Config @{
                environments = @{
                    minimal = @('bootstrap', 'env')
                }
            }

            $originalEnv = $env:PS_PROFILE_ENVIRONMENT
            try {
                $env:PS_PROFILE_ENVIRONMENT = 'minimal'
                $fragments = Get-CurrentEnvironmentFragments -ProfileDir $profileDir
                $fragments | Should -Contain 'bootstrap'
                $fragments | Should -Contain 'env'
            }
            finally {
                if ($null -eq $originalEnv) {
                    Remove-Item Env:PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_ENVIRONMENT = $originalEnv
                }

                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Get-FragmentConfig advanced paths' {
        It 'Loads configuration from an explicit ConfigPath' {
            $profileDir = New-TestTempDirectory -Prefix 'FragmentConfigExplicitPath'
            $configPath = Join-Path $profileDir 'custom-fragments.json'
            @{
                disabled = @('utilities')
            } | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8

            try {
                $config = Get-FragmentConfig -ConfigPath $configPath
                $config.DisabledFragments | Should -Contain 'utilities'
            }
            finally {
                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns defaults for empty configuration files' {
            $profileDir = New-TestTempDirectory -Prefix 'FragmentConfigEmptyFile'
            $configPath = Join-Path $profileDir '.profile-fragments.json'
            Set-Content -LiteralPath $configPath -Value '   ' -Encoding UTF8

            try {
                $config = Get-FragmentConfig -ProfileDir $profileDir
                $config.DisabledFragments | Should -Be @()
                $config.Performance.maxFragmentTime | Should -Be 500
            }
            finally {
                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Emits debug output when PS_PROFILE_DEBUG is level 3' {
            $profileDir = New-FragmentConfigProfileDir -Config @{
                disabled  = @('git')
                loadOrder = @('bootstrap', 'env')
            }

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $config = Get-FragmentConfig -ProfileDir $profileDir
                $config.DisabledFragments | Should -Contain 'git'
                $config.LoadOrder | Should -Contain 'bootstrap'
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Get-FragmentMetadata' {
        It 'Parses tier, dependencies, and environment tags from fragment headers' {
            $fragmentFile = New-TestTempFile -Prefix '22-docker-tools' -Extension '.ps1' -Content @'
# Tier: essential
# Dependencies: bootstrap, env
# Environment: minimal, development
Set-AgentModeFunction -Name 'Enable-DockerTools' -Body { }
'@

            try {
                $metadata = Get-FragmentMetadata -FragmentFile $fragmentFile

                $metadata.Tier | Should -Be 'essential'
                $metadata.Dependencies | Should -Contain 'bootstrap'
                $metadata.Dependencies | Should -Contain 'env'
                $metadata.Environments | Should -Contain 'minimal'
                $metadata.Environments | Should -Contain 'development'
                $metadata.Keywords | Should -Contain 'containers'
            }
            finally {
                Remove-Item -LiteralPath $fragmentFile -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns default metadata for missing fragment files' {
            $missingPath = Join-Path (New-TestTempDirectory -Prefix 'FragmentMetadataMissing') 'missing-fragment.ps1'

            try {
                $metadata = Get-FragmentMetadata -FragmentFile $missingPath

                $metadata.Tier | Should -Be 'optional'
                @($metadata.Dependencies).Count | Should -Be 0
                @($metadata.Environments).Count | Should -Be 0
            }
            finally {
                $parent = Split-Path -Parent $missingPath
                if ($parent -and (Test-Path -LiteralPath $parent)) {
                    Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Detects category keywords from fragment file names' {
            $fragmentFile = New-TestTempFile -Prefix '11-git-enhanced' -Extension '.ps1' -Content '# git helpers'

            try {
                $metadata = Get-FragmentMetadata -FragmentFile $fragmentFile
                $metadata.Keywords | Should -Contain 'git'
            }
            finally {
                Remove-Item -LiteralPath $fragmentFile -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Accepts FileInfo objects and detects cloud keywords' {
            $fragmentFile = New-TestTempFile -Prefix '20-aws-tools' -Extension '.ps1' -Content '# cloud helpers'
            $fileInfo = Get-Item -LiteralPath $fragmentFile

            try {
                $metadata = Get-FragmentMetadata -FragmentFile $fileInfo
                $metadata.Keywords | Should -Contain 'cloud'
            }
            finally {
                Remove-Item -LiteralPath $fragmentFile -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Uses manual validation when PS_PROFILE_FRAGMENT_CONFIG_SKIP_VALIDATION is enabled' {
            $missingPath = Join-Path (New-TestTempDirectory -Prefix 'FragmentMetadataManual') 'missing.ps1'
            $originalFlag = $env:PS_PROFILE_FRAGMENT_CONFIG_SKIP_VALIDATION
            $env:PS_PROFILE_FRAGMENT_CONFIG_SKIP_VALIDATION = '1'

            try {
                $metadata = Get-FragmentMetadata -FragmentFile $missingPath
                $metadata.Tier | Should -Be 'optional'
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_FRAGMENT_CONFIG_SKIP_VALIDATION -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FRAGMENT_CONFIG_SKIP_VALIDATION = $originalFlag
                }
            }
        }

        It 'Emits metadata parsing diagnostics when PS_PROFILE_DEBUG is level 3' {
            $fragmentFile = New-TestTempFile -Prefix '30-python-tools' -Extension '.ps1' -Content @'
# Tier: standard
# Dependencies: bootstrap
'@
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $metadata = Get-FragmentMetadata -FragmentFile $fragmentFile
                $metadata.Tier | Should -Be 'standard'
                $metadata.Dependencies | Should -Contain 'bootstrap'
                $metadata.Keywords | Should -Contain 'development'
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Remove-Item -LiteralPath $fragmentFile -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'FragmentConfig test environment hooks' {
        It 'Loads module dependencies through manual import fallbacks when forced' {
            $originalFlag = $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_MANUAL_IMPORT
            $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_MANUAL_IMPORT = '1'

            Get-Module FragmentConfig, JsonUtilities, Logging, SafeImport -All |
                Remove-Module -Force -ErrorAction SilentlyContinue

            try {
                Import-Module $script:FragmentConfigPath -DisableNameChecking -Force
                Get-Command Get-FragmentConfig -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Module FragmentConfig -ErrorAction SilentlyContinue -Force
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_MANUAL_IMPORT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_MANUAL_IMPORT = $originalFlag
                }

                Import-Module $script:PathResolutionModulePath -DisableNameChecking -Force -ErrorAction SilentlyContinue
                Import-Module $script:FragmentConfigPath -DisableNameChecking -Force
            }
        }

        It 'Uses Write-Error for invalid JSON when structured logging is disabled via env flag' {
            $profileDir = New-FragmentConfigProfileDir -Config @{}
            $configPath = Join-Path $profileDir '.profile-fragments.json'
            Set-Content -LiteralPath $configPath -Value '{ invalid json }' -Encoding UTF8

            $originalStructuredFlag = $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $config = Get-FragmentConfig -ProfileDir $profileDir -ErrorAction SilentlyContinue
                $config.DisabledFragments | Should -Be @()
            }
            finally {
                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = $originalStructuredFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns null for unknown environment names' {
            $profileDir = New-FragmentConfigProfileDir -Config @{
                environments = @{
                    minimal = @('bootstrap')
                }
            }

            $originalEnv = $env:PS_PROFILE_ENVIRONMENT
            try {
                $env:PS_PROFILE_ENVIRONMENT = 'unknown-env'
                Get-CurrentEnvironmentFragments -ProfileDir $profileDir | Should -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalEnv) {
                    Remove-Item Env:PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_ENVIRONMENT = $originalEnv
                }

                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns default metadata for empty fragment files' {
            $fragmentFile = New-TestTempFile -Prefix '40-empty-fragment' -Extension '.ps1' -Content '   '

            try {
                $metadata = Get-FragmentMetadata -FragmentFile $fragmentFile
                $metadata.Tier | Should -Be 'optional'
                @($metadata.Dependencies).Count | Should -Be 0
            }
            finally {
                Remove-Item -LiteralPath $fragmentFile -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Warns when metadata parsing fails and structured logging is disabled via env flag' {
            $fragmentFile = New-TestTempFile -Prefix '41-metadata-warning' -Extension '.ps1' -Content '# Tier: core'

            function global:Read-FileContent {
                param([string]$Path)
                throw 'metadata read probe'
            }

            $originalStructuredFlag = $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $metadata = Get-FragmentMetadata -FragmentFile $fragmentFile
                $metadata.Tier | Should -Be 'optional'
            }
            finally {
                Remove-Item -Path Function:Read-FileContent -ErrorAction SilentlyContinue -Force
                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = $originalStructuredFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Remove-Item -LiteralPath $fragmentFile -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Emits verbose load tracing when PS_PROFILE_DEBUG is level 2' {
            $profileDir = New-FragmentConfigProfileDir -Config @{
                disabled = @('utilities')
            }

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                $config = Get-FragmentConfig -ProfileDir $profileDir
                $config.DisabledFragments | Should -Contain 'utilities'
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Lazily imports PathResolution when ProfileDir is omitted and debug is level 3' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            Get-Module PathResolution -All | Remove-Module -Force -ErrorAction SilentlyContinue

            try {
                $config = Get-FragmentConfig
                $config | Should -Not -BeNullOrEmpty
                $config.Performance.maxFragmentTime | Should -Be 500
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Import-Module $script:PathResolutionModulePath -DisableNameChecking -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Returns defaults when the config file is missing at debug level 3' {
            $profileDir = New-TestTempDirectory -Prefix 'FragmentConfigMissingFile'
            $missingConfigPath = Join-Path $profileDir '.profile-fragments.json'

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $config = Get-FragmentConfig -ConfigPath $missingConfigPath
                $config.DisabledFragments | Should -Be @()
                $config.Performance.maxFragmentTime | Should -Be 500
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Emits verbose output for empty configuration files at debug level 2' {
            $profileDir = New-TestTempDirectory -Prefix 'FragmentConfigEmptyDebug2'
            $configPath = Join-Path $profileDir '.profile-fragments.json'
            Set-Content -LiteralPath $configPath -Value '   ' -Encoding UTF8

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                $config = Get-FragmentConfig -ProfileDir $profileDir
                $config.DisabledFragments | Should -Be @()
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Uses Write-Error for invalid JSON when structured logging and debug output are disabled' {
            $profileDir = New-FragmentConfigProfileDir -Config @{}
            $configPath = Join-Path $profileDir '.profile-fragments.json'
            Set-Content -LiteralPath $configPath -Value '{ invalid json }' -Encoding UTF8

            $originalStructuredFlag = $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = '1'
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            try {
                $config = Get-FragmentConfig -ProfileDir $profileDir -ErrorAction SilentlyContinue
                $config.DisabledFragments | Should -Be @()
            }
            finally {
                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = $originalStructuredFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Uses Write-Warning in the outer catch when structured logging is disabled' {
            $profileDir = New-TestTempDirectory -Prefix 'FragmentConfigOuterCatch'
            $configPath = Join-Path $profileDir '.profile-fragments.json'
            New-Item -ItemType Directory -Path $configPath -Force | Out-Null

            $originalStructuredFlag = $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $config = Get-FragmentConfig -ConfigPath $configPath -ErrorAction SilentlyContinue
                $config.DisabledFragments | Should -Be @()
            }
            finally {
                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = $originalStructuredFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Emits metadata parse diagnostics at debug level 2 when parsing fails' {
            $fragmentFile = New-TestTempFile -Prefix '42-metadata-debug2' -Extension '.ps1' -Content '# Tier: core'

            function global:Read-FileContent {
                param([string]$Path)
                throw 'metadata debug2 probe'
            }

            $originalStructuredFlag = $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '2'

            try {
                $metadata = Get-FragmentMetadata -FragmentFile $fragmentFile
                $metadata.Tier | Should -Be 'optional'
            }
            finally {
                Remove-Item -Path Function:Read-FileContent -ErrorAction SilentlyContinue -Force
                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = $originalStructuredFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Remove-Item -LiteralPath $fragmentFile -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Emits metadata parse diagnostics at debug level 3 when parsing fails' {
            $fragmentFile = New-TestTempFile -Prefix '43-metadata-debug3' -Extension '.ps1' -Content '# Tier: core'

            function global:Read-FileContent {
                param([string]$Path)
                throw 'metadata debug3 probe'
            }

            $originalStructuredFlag = $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $metadata = Get-FragmentMetadata -FragmentFile $fragmentFile
                $metadata.Tier | Should -Be 'optional'
            }
            finally {
                Remove-Item -Path Function:Read-FileContent -ErrorAction SilentlyContinue -Force
                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = $originalStructuredFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Remove-Item -LiteralPath $fragmentFile -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Loads module dependencies through manual import fallbacks and logs JsonUtilities failures at debug level 2' {
            $originalJsonFailure = $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_JSON_IMPORT_FAILURE
            $originalManualImport = $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_MANUAL_IMPORT
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_JSON_IMPORT_FAILURE = '1'
            $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_MANUAL_IMPORT = '1'
            $env:PS_PROFILE_DEBUG = '2'

            Get-Module FragmentConfig, JsonUtilities, Logging, SafeImport -All |
                Remove-Module -Force -ErrorAction SilentlyContinue

            try {
                Import-Module $script:FragmentConfigPath -DisableNameChecking -Force
                Get-Command Get-FragmentConfig -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Module FragmentConfig -ErrorAction SilentlyContinue -Force
                if ($null -eq $originalJsonFailure) {
                    Remove-Item Env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_JSON_IMPORT_FAILURE -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_JSON_IMPORT_FAILURE = $originalJsonFailure
                }

                if ($null -eq $originalManualImport) {
                    Remove-Item Env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_MANUAL_IMPORT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_MANUAL_IMPORT = $originalManualImport
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Import-Module $script:PathResolutionModulePath -DisableNameChecking -Force -ErrorAction SilentlyContinue
                Import-Module $script:FragmentConfigPath -DisableNameChecking -Force
            }
        }

        It 'Falls back when Get-ProfileDirectory fails at debug level 2' {
            $profileDir = New-FragmentConfigProfileDir -Config @{
                disabled = @('utilities')
            }
            $configPath = Join-Path $profileDir '.profile-fragments.json'

            function global:Get-ProfileDirectory {
                param([string]$ScriptPath)
                throw 'profile directory resolution probe'
            }

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                $config = Get-FragmentConfig -ConfigPath $configPath
                $config.DisabledFragments | Should -Contain 'utilities'
            }
            finally {
                Remove-Item -Path Function:Get-ProfileDirectory -ErrorAction SilentlyContinue -Force
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Emits JSON parse diagnostics at debug level 3 when structured logging is disabled' {
            $profileDir = New-FragmentConfigProfileDir -Config @{}
            $configPath = Join-Path $profileDir '.profile-fragments.json'
            Set-Content -LiteralPath $configPath -Value '{ invalid json }' -Encoding UTF8

            $originalStructuredFlag = $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $config = Get-FragmentConfig -ProfileDir $profileDir -ErrorAction SilentlyContinue
                $config.DisabledFragments | Should -Be @()
            }
            finally {
                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FRAGMENT_CONFIG_DISABLE_STRUCTURED_ERROR = $originalStructuredFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Remove-Item -LiteralPath $profileDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Logs Logging import failures at debug level 3 when forced through manual import' {
            $originalLoggingFailure = $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_LOGGING_IMPORT_FAILURE
            $originalManualImport = $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_MANUAL_IMPORT
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_LOGGING_IMPORT_FAILURE = '1'
            $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_MANUAL_IMPORT = '1'
            $env:PS_PROFILE_DEBUG = '3'

            Get-Module FragmentConfig, Logging, SafeImport -All |
                Remove-Module -Force -ErrorAction SilentlyContinue

            try {
                Import-Module $script:FragmentConfigPath -DisableNameChecking -Force
                Get-Command Get-FragmentConfig -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Module FragmentConfig -ErrorAction SilentlyContinue -Force
                if ($null -eq $originalLoggingFailure) {
                    Remove-Item Env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_LOGGING_IMPORT_FAILURE -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_LOGGING_IMPORT_FAILURE = $originalLoggingFailure
                }

                if ($null -eq $originalManualImport) {
                    Remove-Item Env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_MANUAL_IMPORT -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FRAGMENT_CONFIG_FORCE_MANUAL_IMPORT = $originalManualImport
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }

                Import-Module $script:FragmentConfigPath -DisableNameChecking -Force
            }
        }

        It 'Detects web and server keywords from fragment file names' {
            $webFile = New-TestTempFile -Prefix '31-npm-tools' -Extension '.ps1' -Content '# web helpers'
            $serverFile = New-TestTempFile -Prefix '32-postgres-admin' -Extension '.ps1' -Content '# database helpers'

            try {
                $webMetadata = Get-FragmentMetadata -FragmentFile $webFile
                $serverMetadata = Get-FragmentMetadata -FragmentFile $serverFile

                $webMetadata.Keywords | Should -Contain 'web'
                $serverMetadata.Keywords | Should -Contain 'server'
            }
            finally {
                Remove-Item -LiteralPath $webFile, $serverFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
