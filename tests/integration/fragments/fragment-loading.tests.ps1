<#
tests/integration/fragments/fragment-loading.tests.ps1

.SYNOPSIS
    Integration tests for fragment loading workflow using new modules.
#>


BeforeAll {
    try {
        # Import required modules
        $pathResolutionModulePath = Get-TestPath -RelativePath 'scripts\lib\path\PathResolution.psm1' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $pathResolutionModulePath -or [string]::IsNullOrWhiteSpace($pathResolutionModulePath)) {
            throw "Get-TestPath returned null or empty value for pathResolutionModulePath"
        }
        if (-not (Test-Path -LiteralPath $pathResolutionModulePath)) {
            throw "PathResolution module not found at: $pathResolutionModulePath"
        }
        Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction Stop

        $fragmentConfigModulePath = Get-TestPath -RelativePath 'scripts\lib\fragment\FragmentConfig.psm1' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $fragmentConfigModulePath -or [string]::IsNullOrWhiteSpace($fragmentConfigModulePath)) {
            throw "Get-TestPath returned null or empty value for fragmentConfigModulePath"
        }
        if (-not (Test-Path -LiteralPath $fragmentConfigModulePath)) {
            throw "FragmentConfig module not found at: $fragmentConfigModulePath"
        }
        Import-Module $fragmentConfigModulePath -DisableNameChecking -ErrorAction Stop

        $fragmentLoadingModulePath = Get-TestPath -RelativePath 'scripts\lib\fragment\FragmentLoading.psm1' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $fragmentLoadingModulePath -or [string]::IsNullOrWhiteSpace($fragmentLoadingModulePath)) {
            throw "Get-TestPath returned null or empty value for fragmentLoadingModulePath"
        }
        if (-not (Test-Path -LiteralPath $fragmentLoadingModulePath)) {
            throw "FragmentLoading module not found at: $fragmentLoadingModulePath"
        }
        Import-Module $fragmentLoadingModulePath -DisableNameChecking -ErrorAction Stop

        $fragmentIdempotencyModulePath = Get-TestPath -RelativePath 'scripts\lib\fragment\FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $fragmentIdempotencyModulePath -or [string]::IsNullOrWhiteSpace($fragmentIdempotencyModulePath)) {
            throw "Get-TestPath returned null or empty value for fragmentIdempotencyModulePath"
        }
        if (-not (Test-Path -LiteralPath $fragmentIdempotencyModulePath)) {
            throw "FragmentIdempotency module not found at: $fragmentIdempotencyModulePath"
        }
        Import-Module $fragmentIdempotencyModulePath -DisableNameChecking -ErrorAction Stop

        # Get test data directory
        $testDataDir = Join-Path $PSScriptRoot '..' '..' 'test-data'
        if ($testDataDir -and -not [string]::IsNullOrWhiteSpace($testDataDir) -and -not (Test-Path -LiteralPath $testDataDir)) {
            New-Item -Path $testDataDir -ItemType Directory -Force | Out-Null
        }
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to initialize fragment loading tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }
}

Describe 'Fragment Loading Integration' {
    Context 'End-to-end fragment loading workflow' {
        It 'Loads fragments in correct dependency order' {
            $tempProfileDir = $null
            $cleanupNeeded = $false

            try {
                $tempProfileDir = Join-Path $testDataDir 'fragment-loading-integration'
                if ($tempProfileDir -and -not [string]::IsNullOrWhiteSpace($tempProfileDir) -and (Test-Path -LiteralPath $tempProfileDir)) {
                    Remove-Item $tempProfileDir -Recurse -Force -ErrorAction SilentlyContinue
                }
                New-Item -Path $tempProfileDir -ItemType Directory -Force | Out-Null
                $profileDDir = Join-Path $tempProfileDir 'profile.d'
                New-Item -Path $profileDDir -ItemType Directory -Force | Out-Null
                $cleanupNeeded = $true

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

                $bIndex | Should -BeLessThan $aIndex -Because "Fragment B (dependency) should load before Fragment A"
                $bIndex | Should -BeLessThan $cIndex -Because "Fragment B (dependency) should load before Fragment C"

                # Simulate loading
                $global:FragmentALoaded = $false
                $global:FragmentBLoaded = $false
                $global:FragmentCLoaded = $false

                foreach ($fragment in $sortedFragments) {
                    . $fragment.FullName
                }

                # Verify all loaded
                $global:FragmentALoaded | Should -Be $true -Because "Fragment A should be loaded after dependency resolution"
                $global:FragmentBLoaded | Should -Be $true -Because "Fragment B should be loaded"
                $global:FragmentCLoaded | Should -Be $true -Because "Fragment C should be loaded after dependency resolution"
            }
            catch {
                $errorDetails = @{
                    Message        = $_.Exception.Message
                    TempProfileDir = $tempProfileDir
                    Category       = $_.CategoryInfo.Category
                }
                Write-Error "Fragment dependency order test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                if ($cleanupNeeded) {
                    Remove-Item $tempProfileDir -Recurse -Force -ErrorAction SilentlyContinue
                    $global:FragmentALoaded = $null
                    $global:FragmentBLoaded = $null
                    $global:FragmentCLoaded = $null
                }
            }
        }

        It 'Respects disabled fragments from configuration' {
            $tempProfileDir = Join-Path $testDataDir 'fragment-disabled-integration'
            if ($tempProfileDir -and -not [string]::IsNullOrWhiteSpace($tempProfileDir) -and (Test-Path -LiteralPath $tempProfileDir)) {
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
            if ($tempProfileDir -and -not [string]::IsNullOrWhiteSpace($tempProfileDir) -and (Test-Path -LiteralPath $tempProfileDir)) {
                Remove-Item $tempProfileDir -Recurse -Force
            }
            New-Item -Path $tempProfileDir -ItemType Directory -Force | Out-Null
            $profileDDir = Join-Path $tempProfileDir 'profile.d'
            New-Item -Path $profileDDir -ItemType Directory -Force | Out-Null

            # Create test fragments
            Set-Content -Path (Join-Path $profileDDir 'bootstrap.ps1') -Value '$global:BootstrapLoaded = $true'
            Set-Content -Path (Join-Path $profileDDir 'env.ps1') -Value '$global:EnvLoaded = $true'
            Set-Content -Path (Join-Path $profileDDir 'git.ps1') -Value '$global:GitLoaded = $true'

            # Create configuration with environment sets
            $configJson = @{
                environments = @{
                    minimal = @('bootstrap', 'env')
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

                $currentEnvFragments | Should -Contain 'bootstrap'
                $currentEnvFragments | Should -Contain 'env'
                $currentEnvFragments | Should -Not -Contain 'git'
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

