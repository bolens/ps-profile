<#
tests/unit/library-fragment-config-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FragmentConfig accessor and metadata helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $pathResolutionModulePath = Get-TestPath -RelativePath 'scripts\lib\path\PathResolution.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction Stop

    $fragmentConfigPath = Get-TestPath -RelativePath 'scripts\lib\fragment\FragmentConfig.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentConfigPath -DisableNameChecking -ErrorAction Stop

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
    }
}
