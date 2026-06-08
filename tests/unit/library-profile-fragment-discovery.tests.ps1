<#
tests/unit/library-profile-fragment-discovery.tests.ps1

.SYNOPSIS
    Unit tests for ProfileFragmentDiscovery ordering logic.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $libPath = Join-Path $PSScriptRoot '../../scripts/lib'
    Import-Module (Join-Path $libPath 'profile/ProfileFragmentDiscovery.psm1') -DisableNameChecking -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'ProfileFragmentDiscoveryTests'
    $script:FragmentDir = Join-Path $script:TempDir 'profile.d'
    New-Item -ItemType Directory -Path $script:FragmentDir -Force | Out-Null

    foreach ($name in @('bootstrap.ps1', '20-beta.ps1', '10-alpha.ps1')) {
        Set-Content -LiteralPath (Join-Path $script:FragmentDir $name) -Value "# $name" -Encoding UTF8
    }

    $script:AllFragments = @(Get-ChildItem -Path $script:FragmentDir -Filter '*.ps1' -File)
    $script:MissingLoadingModule = Join-Path $script:TempDir 'missing-fragment-loading.psm1'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ProfileFragmentDiscovery Module' {
    Context 'Initialize-FragmentDiscovery' {
        It 'Loads bootstrap fragments before all other fragments' {
            $result = Initialize-FragmentDiscovery `
                -AllFragments $script:AllFragments `
                -FragmentLoadingModule $script:MissingLoadingModule `
                -FragmentLoadingModuleExists $false `
                -PerformanceConfig @{} `
                -FragmentLibDir (Join-Path $script:TempDir 'lib')

            @($result.BootstrapFragment).Count | Should -Be 1
            $result.BootstrapFragment[0].BaseName | Should -Be 'bootstrap'
            @($result.FragmentsToLoad)[0].BaseName | Should -Be 'bootstrap'
        }

        It 'Applies manual load order overrides before remaining fragments' {
            $result = Initialize-FragmentDiscovery `
                -AllFragments $script:AllFragments `
                -LoadOrderOverride @('20-beta') `
                -FragmentLoadingModule $script:MissingLoadingModule `
                -FragmentLoadingModuleExists $false `
                -PerformanceConfig @{} `
                -FragmentLibDir (Join-Path $script:TempDir 'lib')

            $names = @($result.NonBootstrapFragments | ForEach-Object { $_.BaseName })
            $names[0] | Should -Be '20-beta'
            $names[1] | Should -Be '10-alpha'
        }

        It 'Excludes disabled fragments from the disabled set lookup' {
            $result = Initialize-FragmentDiscovery `
                -AllFragments $script:AllFragments `
                -DisabledFragments @('10-alpha', 'bootstrap') `
                -FragmentLoadingModule $script:MissingLoadingModule `
                -FragmentLoadingModuleExists $false `
                -PerformanceConfig @{} `
                -FragmentLibDir (Join-Path $script:TempDir 'lib')

            $result.DisabledSet.Contains('10-alpha') | Should -Be $true
            $result.DisabledSet.Contains('bootstrap') | Should -Be $true
            @($result.FragmentsToLoad | ForEach-Object { $_.BaseName }) | Should -Contain 'bootstrap'
        }
    }
}
