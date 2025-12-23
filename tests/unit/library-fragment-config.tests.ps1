<#
tests/unit/library-fragment-config.tests.ps1

.SYNOPSIS
    Unit tests for FragmentConfig.psm1 module functions.
#>

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    # Import PathResolution first (FragmentConfig depends on it)
    $pathResolutionModulePath = Get-TestPath -RelativePath 'scripts\lib\path\PathResolution.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction Stop

    # Import the FragmentConfig module
    $fragmentConfigPath = Get-TestPath -RelativePath 'scripts\lib\fragment\FragmentConfig.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentConfigPath -DisableNameChecking -ErrorAction Stop

    # Get test data directory
    $testDataDir = Join-Path $PSScriptRoot '..' 'test-data'
    if (-not (Test-Path $testDataDir)) {
        New-Item -Path $testDataDir -ItemType Directory -Force | Out-Null
    }
}

Describe 'Get-FragmentConfig' {
    Context 'When configuration file does not exist' {
        It 'Returns default configuration' {
            $tempProfileDir = Join-Path $testDataDir 'fragment-config-test-nonexistent'
            if (Test-Path $tempProfileDir) {
                Remove-Item $tempProfileDir -Recurse -Force
            }
            New-Item -Path $tempProfileDir -ItemType Directory -Force | Out-Null

            $config = Get-FragmentConfig -ProfileDir $tempProfileDir

            $config | Should -Not -BeNullOrEmpty
            $config.DisabledFragments | Should -Be @()
            $config.LoadOrder | Should -Be @()
            $config.Environments | Should -BeOfType [hashtable]
            $config.FeatureFlags | Should -BeOfType [hashtable]
            $config.Performance.batchLoad | Should -Be $false
            $config.Performance.maxFragmentTime | Should -Be 500

            Remove-Item $tempProfileDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'When configuration file exists' {
        It 'Parses valid configuration correctly' {
            $tempProfileDir = Join-Path $testDataDir 'fragment-config-test-valid'
            if (Test-Path $tempProfileDir) {
                Remove-Item $tempProfileDir -Recurse -Force
            }
            New-Item -Path $tempProfileDir -ItemType Directory -Force | Out-Null

            $configJson = @{
                disabled     = @('git', 'containers')
                loadOrder    = @('bootstrap', 'env', 'utilities')
                environments = @{
                    minimal     = @('bootstrap', 'env')
                    development = @('bootstrap', 'env', 'git')
                }
                featureFlags = @{
                    enableAdvancedFeatures = $true
                }
                performance  = @{
                    batchLoad       = $true
                    maxFragmentTime = 1000
                }
            } | ConvertTo-Json

            $configPath = Join-Path $tempProfileDir '.profile-fragments.json'
            Set-Content -Path $configPath -Value $configJson

            $config = Get-FragmentConfig -ProfileDir $tempProfileDir

            $config.DisabledFragments | Should -Contain 'git'
            $config.DisabledFragments | Should -Contain 'containers'
            $config.LoadOrder | Should -Contain 'bootstrap'
            $config.Environments['minimal'] | Should -Contain 'bootstrap'
            $config.Environments['development'] | Should -Contain 'git'
            $config.FeatureFlags['enableAdvancedFeatures'] | Should -Be $true
            $config.Performance.batchLoad | Should -Be $true
            $config.Performance.maxFragmentTime | Should -Be 1000

            Remove-Item $tempProfileDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'Handles invalid JSON gracefully' {
            $tempProfileDir = Join-Path $testDataDir 'fragment-config-test-invalid'
            if (Test-Path $tempProfileDir) {
                Remove-Item $tempProfileDir -Recurse -Force
            }
            New-Item -Path $tempProfileDir -ItemType Directory -Force | Out-Null

            $configPath = Join-Path $tempProfileDir '.profile-fragments.json'
            Set-Content -Path $configPath -Value '{ invalid json }'

            $config = Get-FragmentConfig -ProfileDir $tempProfileDir

            # Should return default config on error
            $config | Should -Not -BeNullOrEmpty
            $config.DisabledFragments | Should -Be @()

            Remove-Item $tempProfileDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Get-FragmentConfigValue' {
    Context 'When key exists' {
        It 'Returns the correct value' {
            $tempProfileDir = Join-Path $testDataDir 'fragment-config-value-test'
            if (Test-Path $tempProfileDir) {
                Remove-Item $tempProfileDir -Recurse -Force
            }
            New-Item -Path $tempProfileDir -ItemType Directory -Force | Out-Null

            $configJson = @{
                performance = @{
                    batchLoad       = $true
                    maxFragmentTime = 1000
                }
            } | ConvertTo-Json

            $configPath = Join-Path $tempProfileDir '.profile-fragments.json'
            Set-Content -Path $configPath -Value $configJson

            $value = Get-FragmentConfigValue -Key 'Performance.batchLoad' -ProfileDir $tempProfileDir
            $value | Should -Be $true

            $value2 = Get-FragmentConfigValue -Key 'Performance.maxFragmentTime' -ProfileDir $tempProfileDir
            $value2 | Should -Be 1000

            Remove-Item $tempProfileDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'When key does not exist' {
        It 'Returns default value' {
            $tempProfileDir = Join-Path $testDataDir 'fragment-config-value-default'
            if (Test-Path $tempProfileDir) {
                Remove-Item $tempProfileDir -Recurse -Force
            }
            New-Item -Path $tempProfileDir -ItemType Directory -Force | Out-Null

            $value = Get-FragmentConfigValue -Key 'Nonexistent.Key' -DefaultValue 'default' -ProfileDir $tempProfileDir
            $value | Should -Be 'default'

            Remove-Item $tempProfileDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Get-DisabledFragments' {
    It 'Returns disabled fragments from configuration' {
        $tempProfileDir = Join-Path $testDataDir 'fragment-config-disabled'
        if (Test-Path $tempProfileDir) {
            Remove-Item $tempProfileDir -Recurse -Force
        }
        New-Item -Path $tempProfileDir -ItemType Directory -Force | Out-Null

        $configJson = @{
            disabled = @('git', 'containers')
        } | ConvertTo-Json

        $configPath = Join-Path $tempProfileDir '.profile-fragments.json'
        Set-Content -Path $configPath -Value $configJson

        $disabled = Get-DisabledFragments -ProfileDir $tempProfileDir
        $disabled | Should -Contain 'git'
        $disabled | Should -Contain 'containers'

        Remove-Item $tempProfileDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Get-CurrentEnvironmentFragments' {
    It 'Returns fragments for current environment when set' {
        $tempProfileDir = Join-Path $testDataDir 'fragment-config-env'
        if (Test-Path $tempProfileDir) {
            Remove-Item $tempProfileDir -Recurse -Force
        }
        New-Item -Path $tempProfileDir -ItemType Directory -Force | Out-Null

        $configJson = @{
            environments = @{
                minimal = @('bootstrap', 'env')
            }
        } | ConvertTo-Json

        $configPath = Join-Path $tempProfileDir '.profile-fragments.json'
        Set-Content -Path $configPath -Value $configJson

        $originalEnv = $env:PS_PROFILE_ENVIRONMENT
        try {
            $env:PS_PROFILE_ENVIRONMENT = 'minimal'
            $fragments = Get-CurrentEnvironmentFragments -ProfileDir $tempProfileDir
            $fragments | Should -Contain 'bootstrap'
            $fragments | Should -Contain 'env'
        }
        finally {
            $env:PS_PROFILE_ENVIRONMENT = $originalEnv
        }

        Remove-Item $tempProfileDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Returns null when environment is not set' {
        $originalEnv = $env:PS_PROFILE_ENVIRONMENT
        try {
            $env:PS_PROFILE_ENVIRONMENT = $null
            $fragments = Get-CurrentEnvironmentFragments
            $fragments | Should -BeNullOrEmpty
        }
        finally {
            $env:PS_PROFILE_ENVIRONMENT = $originalEnv
        }
    }
}

