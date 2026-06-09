<#
tests/unit/library-fragment-config.tests.ps1

.SYNOPSIS
    Unit tests for FragmentConfig.psm1 module functions.
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
    # Import PathResolution first (FragmentConfig depends on it)
    $pathResolutionModulePath = Get-TestPath -RelativePath 'scripts\lib\path\PathResolution.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction Stop

    # Import the FragmentConfig module
    $fragmentConfigPath = Get-TestPath -RelativePath 'scripts\lib\fragment\FragmentConfig.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentConfigPath -DisableNameChecking -ErrorAction Stop
}

Describe 'Get-FragmentConfig' {
    Context 'When configuration file does not exist' {
        It 'Returns default configuration' {
            $tempProfileDir = New-TestTempDirectory -Prefix 'FragmentConfigNonexistent'

            $config = Get-FragmentConfig -ProfileDir $tempProfileDir

            $config | Should -Not -BeNullOrEmpty
            $config.DisabledFragments | Should -Be @()
            $config.LoadOrder | Should -Be @()
            $config.Environments | Should -BeOfType [hashtable]
            $config.FeatureFlags | Should -BeOfType [hashtable]
            $config.Performance.batchLoad | Should -Be $false
            $config.Performance.maxFragmentTime | Should -Be 500
        }
    }

    Context 'When configuration file exists' {
        It 'Parses valid configuration correctly' {
            $tempProfileDir = New-TestTempDirectory -Prefix 'FragmentConfigValid'

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
        }

        It 'Handles invalid JSON gracefully' {
            $tempProfileDir = New-TestTempDirectory -Prefix 'FragmentConfigInvalid'

            $configPath = Join-Path $tempProfileDir '.profile-fragments.json'
            Set-Content -Path $configPath -Value '{ invalid json }'

            $config = Get-FragmentConfig -ProfileDir $tempProfileDir

            # Should return default config on error
            $config | Should -Not -BeNullOrEmpty
            $config.DisabledFragments | Should -Be @()
        }
    }
}

Describe 'Get-FragmentConfigValue' {
    Context 'When key exists' {
        It 'Returns the correct value' {
            $tempProfileDir = New-TestTempDirectory -Prefix 'FragmentConfigValue'

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
        }
    }

    Context 'When key does not exist' {
        It 'Returns default value' {
            $tempProfileDir = New-TestTempDirectory -Prefix 'FragmentConfigValueDefault'

            $value = Get-FragmentConfigValue -Key 'Nonexistent.Key' -DefaultValue 'default' -ProfileDir $tempProfileDir
            $value | Should -Be 'default'
        }
    }
}

Describe 'Get-DisabledFragments' {
    It 'Returns disabled fragments from configuration' {
        $tempProfileDir = New-TestTempDirectory -Prefix 'FragmentConfigDisabled'

        $configJson = @{
            disabled = @('git', 'containers')
        } | ConvertTo-Json

        $configPath = Join-Path $tempProfileDir '.profile-fragments.json'
        Set-Content -Path $configPath -Value $configJson

        $disabled = Get-DisabledFragments -ProfileDir $tempProfileDir
        $disabled | Should -Contain 'git'
        $disabled | Should -Contain 'containers'
    }
}

Describe 'Get-CurrentEnvironmentFragments' {
    It 'Returns fragments for current environment when set' {
        $tempProfileDir = New-TestTempDirectory -Prefix 'FragmentConfigEnv'

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
            if ($null -eq $originalEnv) {
                Remove-Item Env:PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_ENVIRONMENT = $originalEnv
            }
        }
    }

    It 'Returns null when environment is not set' {
        $originalEnv = $env:PS_PROFILE_ENVIRONMENT
        try {
            Remove-Item Env:PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
            $fragments = Get-CurrentEnvironmentFragments
            $fragments | Should -BeNullOrEmpty
        }
        finally {
            if ($null -eq $originalEnv) {
                Remove-Item Env:PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_ENVIRONMENT = $originalEnv
            }
        }
    }
}
