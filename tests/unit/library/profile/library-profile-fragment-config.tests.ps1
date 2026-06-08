<#
tests/unit/library-profile-fragment-config.tests.ps1

.SYNOPSIS
    Unit tests for ProfileFragmentConfig module.
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
    $libPath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib'
    Import-Module (Join-Path $libPath 'profile/ProfileFragmentConfig.psm1') -DisableNameChecking -Force -Global

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'ProfileFragmentConfigTests'
    $script:FragmentDir = Join-Path $script:TempDir 'profile.d'
    New-Item -ItemType Directory -Path $script:FragmentDir -Force | Out-Null

    foreach ($name in @('bootstrap.ps1', '10-alpha.ps1', '99-test-stub.ps1')) {
        Set-Content -LiteralPath (Join-Path $script:FragmentDir $name) -Value "# $name" -Encoding UTF8
    }

    $script:MissingConfigModule = Join-Path $script:TempDir 'missing-fragment-config.psm1'
    $script:RealConfigModule = Join-Path $script:RepoRoot 'scripts/lib/fragment/FragmentConfig.psm1'
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_LOAD_ALL -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ProfileFragmentConfig Module' {
    Context 'Test-EnvBool' {
        It 'Treats 1 and true as enabled' {
            Test-EnvBool -Value '1' | Should -Be $true
            Test-EnvBool -Value 'true' | Should -Be $true
            Test-EnvBool -Value 'TRUE' | Should -Be $true
        }

        It 'Treats empty, 0, and false as disabled' {
            Test-EnvBool -Value '' | Should -Be $false
            Test-EnvBool -Value '0' | Should -Be $false
            Test-EnvBool -Value 'false' | Should -Be $false
        }
    }

    Context 'Initialize-FragmentConfiguration' {
        AfterEach {
            Remove-Item Env:\PS_PROFILE_LOAD_ALL -ErrorAction SilentlyContinue
            Remove-Item Env:\PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
            Remove-Item Env:\PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue
        }

        It 'Returns default structure when the config module is missing' {
            $result = Initialize-FragmentConfiguration `
                -ProfileDir $script:TempDir `
                -FragmentConfigModule $script:MissingConfigModule

            $result.ProfileDExists | Should -Be $true
            $result.PerformanceConfig.parallelDependencyParsing | Should -Be $true
            $result.FragmentLoadingModule | Should -Match 'FragmentLoading\.psm1$'
            @($result.DisabledFragments).Count | Should -Be 0
        }

        It 'Excludes test fragments unless PS_PROFILE_TEST_MODE is enabled' {
            Remove-Item Env:\PS_PROFILE_TEST_MODE -ErrorAction SilentlyContinue

            $result = Initialize-FragmentConfiguration `
                -ProfileDir $script:TempDir `
                -FragmentConfigModule $script:MissingConfigModule

            $names = @($result.AllFragments | ForEach-Object { $_.BaseName })
            $names | Should -Contain '10-alpha'
            $names | Should -Not -Contain '99-test-stub'
        }

        It 'Includes test fragments when PS_PROFILE_TEST_MODE is enabled' {
            $env:PS_PROFILE_TEST_MODE = '1'

            $result = Initialize-FragmentConfiguration `
                -ProfileDir $script:TempDir `
                -FragmentConfigModule $script:MissingConfigModule

            $names = @($result.AllFragments | ForEach-Object { $_.BaseName })
            $names | Should -Contain '99-test-stub'
        }

        It 'Loads repository fragment configuration when the module exists' {
            if (-not (Test-Path -LiteralPath $script:RealConfigModule)) {
                Set-ItResult -Inconclusive -Because 'FragmentConfig module is unavailable in this workspace'
                return
            }

            $result = Initialize-FragmentConfiguration `
                -ProfileDir $script:RepoRoot `
                -FragmentConfigModule $script:RealConfigModule

            $result.FragmentLibDir | Should -Match ([regex]::Escape('scripts/lib/fragment'))
            $result.ProfileDExists | Should -Be $true
            @($result.AllFragments).Count | Should -BeGreaterThan 0
        }

        It 'Clears disabled fragments when PS_PROFILE_LOAD_ALL is enabled' {
            if (-not (Test-Path -LiteralPath $script:RealConfigModule)) {
                Set-ItResult -Inconclusive -Because 'FragmentConfig module is unavailable in this workspace'
                return
            }

            $configPath = Join-Path $script:TempDir '.profile-fragments.json'
            Set-Content -LiteralPath $configPath -Value '{"disabled":["10-alpha"]}' -Encoding UTF8

            $withoutLoadAll = Initialize-FragmentConfiguration `
                -ProfileDir $script:TempDir `
                -FragmentConfigModule $script:RealConfigModule

            $env:PS_PROFILE_LOAD_ALL = '1'
            $withLoadAll = Initialize-FragmentConfiguration `
                -ProfileDir $script:TempDir `
                -FragmentConfigModule $script:RealConfigModule

            @($withoutLoadAll.DisabledFragments).Count | Should -BeGreaterThan 0
            @($withLoadAll.DisabledFragments).Count | Should -Be 0
        }
    }
}
