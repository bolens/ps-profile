<#
tests/integration/fragment-loading.tests.ps1

.SYNOPSIS
    Integration tests for fragment loading workflow using new modules.
#>

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    # Import required modules
    $pathResolutionModulePath = Get-TestPath -RelativePath 'scripts\lib\PathResolution.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction Stop

    $fragmentConfigModulePath = Get-TestPath -RelativePath 'scripts\lib\FragmentConfig.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentConfigModulePath -DisableNameChecking -ErrorAction Stop

    $fragmentLoadingModulePath = Get-TestPath -RelativePath 'scripts\lib\FragmentLoading.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentLoadingModulePath -DisableNameChecking -ErrorAction Stop

    $fragmentIdempotencyModulePath = Get-TestPath -RelativePath 'scripts\lib\FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyModulePath -DisableNameChecking -ErrorAction Stop

    # Get test data directory
    $testDataDir = Join-Path $PSScriptRoot '..' 'test-data'
    if (-not (Test-Path $testDataDir)) {
        New-Item -Path $testDataDir -ItemType Directory -Force | Out-Null
    }
}

Describe 'Fragment Loading Integration' {
    Context 'End-to-end fragment loading workflow' {
        It 'Loads fragments in correct dependency order' {
            $tempProfileDir = Join-Path $testDataDir 'fragment-loading-integration'
            if (Test-Path $tempProfileDir) {
                Remove-Item $tempProfileDir -Recurse -Force
            }
            New-Item -Path $tempProfileDir -ItemType Directory -Force | Out-Null
            $profileDDir = Join-Path $tempProfileDir 'profile.d'
            New-Item -Path $profileDDir -ItemType Directory -Force | Out-Null

            # Create test fragments with dependencies
            # Fragment B has no dependencies
            Set-Content -Path (Join-Path $profileDDir '20-fragment-b.ps1') -Value @'
# Fragment B - no dependencies
$global:FragmentBLoaded = $true
'@

            # Fragment A depends on B
            Set-Content -Path (Join-Path $profileDDir '10-fragment-a.ps1') -Value @'
# Dependencies: 20-fragment-b
# Fragment A depends on B
$global:FragmentALoaded = $true
'@

            # Fragment C depends on B
            Set-Content -Path (Join-Path $profileDDir '30-fragment-c.ps1') -Value @'
# Dependencies: 20-fragment-b
# Fragment C depends on B
$global:FragmentCLoaded = $true
'@

            # Get fragments
            $fragments = Get-ChildItem -Path $profileDDir -Filter '*.ps1'

            # Get load order using FragmentLoading module
            $sortedFragments = Get-FragmentLoadOrder -FragmentFiles $fragments

            # Verify B comes before A and C
            $bIndex = [array]::IndexOf($sortedFragments.BaseName, '20-fragment-b')
            $aIndex = [array]::IndexOf($sortedFragments.BaseName, '10-fragment-a')
            $cIndex = [array]::IndexOf($sortedFragments.BaseName, '30-fragment-c')

            $bIndex | Should -BeLessThan $aIndex
            $bIndex | Should -BeLessThan $cIndex

            # Simulate loading
            $global:FragmentALoaded = $false
            $global:FragmentBLoaded = $false
            $global:FragmentCLoaded = $false

            foreach ($fragment in $sortedFragments) {
                . $fragment.FullName
            }

            # Verify all loaded
            $global:FragmentALoaded | Should -Be $true
            $global:FragmentBLoaded | Should -Be $true
            $global:FragmentCLoaded | Should -Be $true

            # Cleanup
            Remove-Item $tempProfileDir -Recurse -Force -ErrorAction SilentlyContinue
            $global:FragmentALoaded = $null
            $global:FragmentBLoaded = $null
            $global:FragmentCLoaded = $null
        }

        It 'Respects disabled fragments from configuration' {
            $tempProfileDir = Join-Path $testDataDir 'fragment-disabled-integration'
            if (Test-Path $tempProfileDir) {
                Remove-Item $tempProfileDir -Recurse -Force
            }
            New-Item -Path $tempProfileDir -ItemType Directory -Force | Out-Null
            $profileDDir = Join-Path $tempProfileDir 'profile.d'
            New-Item -Path $profileDDir -ItemType Directory -Force | Out-Null

            # Create test fragments
            Set-Content -Path (Join-Path $profileDDir '10-fragment.ps1') -Value '$global:Fragment10Loaded = $true'
            Set-Content -Path (Join-Path $profileDDir '20-fragment.ps1') -Value '$global:Fragment20Loaded = $true'

            # Create configuration with disabled fragment
            $configJson = @{
                disabled = @('20-fragment')
            } | ConvertTo-Json

            $configPath = Join-Path $tempProfileDir '.profile-fragments.json'
            Set-Content -Path $configPath -Value $configJson

            # Load configuration
            $config = Get-FragmentConfig -ProfileDir $tempProfileDir
            $disabledFragments = $config.DisabledFragments

            # Get fragments and filter disabled
            $fragments = Get-ChildItem -Path $profileDDir -Filter '*.ps1'
            $sortedFragments = Get-FragmentLoadOrder -FragmentFiles $fragments -DisabledFragments $disabledFragments

            # Verify disabled fragment is excluded
            $sortedFragments.BaseName | Should -Contain '10-fragment'
            $sortedFragments.BaseName | Should -Not -Contain '20-fragment'

            # Cleanup
            Remove-Item $tempProfileDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'Handles environment-specific fragment sets' {
            $tempProfileDir = Join-Path $testDataDir 'fragment-env-integration'
            if (Test-Path $tempProfileDir) {
                Remove-Item $tempProfileDir -Recurse -Force
            }
            New-Item -Path $tempProfileDir -ItemType Directory -Force | Out-Null
            $profileDDir = Join-Path $tempProfileDir 'profile.d'
            New-Item -Path $profileDDir -ItemType Directory -Force | Out-Null

            # Create test fragments
            Set-Content -Path (Join-Path $profileDDir '00-bootstrap.ps1') -Value '$global:BootstrapLoaded = $true'
            Set-Content -Path (Join-Path $profileDDir '01-env.ps1') -Value '$global:EnvLoaded = $true'
            Set-Content -Path (Join-Path $profileDDir '11-git.ps1') -Value '$global:GitLoaded = $true'

            # Create configuration with environment sets
            $configJson = @{
                environments = @{
                    minimal = @('00-bootstrap', '01-env')
                }
            } | ConvertTo-Json

            $configPath = Join-Path $tempProfileDir '.profile-fragments.json'
            Set-Content -Path $configPath -Value $configJson

            # Set environment
            $originalEnv = $env:PS_PROFILE_ENVIRONMENT
            try {
                $env:PS_PROFILE_ENVIRONMENT = 'minimal'

                # Load configuration
                $config = Get-FragmentConfig -ProfileDir $tempProfileDir
                $currentEnvFragments = Get-CurrentEnvironmentFragments -ProfileDir $tempProfileDir

                $currentEnvFragments | Should -Contain '00-bootstrap'
                $currentEnvFragments | Should -Contain '01-env'
                $currentEnvFragments | Should -Not -Contain '11-git'
            }
            finally {
                $env:PS_PROFILE_ENVIRONMENT = $originalEnv
            }

            # Cleanup
            Remove-Item $tempProfileDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Fragment idempotency integration' {
        It 'Prevents double-loading of fragments' {
            $tempFragment = Join-Path $testDataDir 'fragment-idempotency-test.ps1'
            Set-Content -Path $tempFragment -Value @'
# Test fragment
$global:FragmentLoadCount = ($global:FragmentLoadCount + 1)
'@

            # Clear any existing state
            Clear-FragmentLoaded -FragmentName 'fragment-idempotency-test' -ErrorAction SilentlyContinue
            $global:FragmentLoadCount = 0

            # First load
            if (-not (Test-FragmentLoaded -FragmentName 'fragment-idempotency-test')) {
                . $tempFragment
                Set-FragmentLoaded -FragmentName 'fragment-idempotency-test'
            }

            $global:FragmentLoadCount | Should -Be 1

            # Second load attempt (should be skipped)
            if (-not (Test-FragmentLoaded -FragmentName 'fragment-idempotency-test')) {
                . $tempFragment
                Set-FragmentLoaded -FragmentName 'fragment-idempotency-test'
            }

            $global:FragmentLoadCount | Should -Be 1

            # Cleanup
            Clear-FragmentLoaded -FragmentName 'fragment-idempotency-test'
            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
            $global:FragmentLoadCount = $null
        }
    }
}

