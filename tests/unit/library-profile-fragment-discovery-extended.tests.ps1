<#
tests/unit/library-profile-fragment-discovery-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ProfileFragmentDiscovery edge cases.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $libPath = Join-Path $PSScriptRoot '../../scripts/lib'
    Import-Module (Join-Path $libPath 'profile/ProfileFragmentDiscovery.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $libPath 'fragment/FragmentLoading.psm1') -DisableNameChecking -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'ProfileFragmentDiscoveryExtended'
    $script:FragmentDir = Join-Path $script:TempDir 'profile.d'
    New-Item -ItemType Directory -Path $script:FragmentDir -Force | Out-Null

    foreach ($name in @('bootstrap.ps1', '20-beta.ps1', '10-alpha.ps1')) {
        Set-Content -LiteralPath (Join-Path $script:FragmentDir $name) -Value "# $name" -Encoding UTF8
    }

    $script:AllFragments = @(Get-ChildItem -Path $script:FragmentDir -Filter '*.ps1' -File)
    $script:FragmentLoadingModule = Join-Path $libPath 'fragment/FragmentLoading.psm1'
    $script:FragmentLibDir = Join-Path $script:TempDir 'lib'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ProfileFragmentDiscovery extended scenarios' {
    Context 'Initialize-FragmentDiscovery edge cases' {
        It 'Handles bootstrap-only fragment sets without non-bootstrap entries' {
            $bootstrapOnlyDir = Join-Path $script:TempDir 'bootstrap-only'
            New-Item -ItemType Directory -Path $bootstrapOnlyDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $bootstrapOnlyDir 'bootstrap.ps1') -Value '# bootstrap only' -Encoding UTF8
            $bootstrapOnly = @(Get-ChildItem -Path $bootstrapOnlyDir -Filter '*.ps1' -File)

            $result = Initialize-FragmentDiscovery `
                -AllFragments $bootstrapOnly `
                -FragmentLoadingModule $script:FragmentLoadingModule `
                -FragmentLoadingModuleExists $false `
                -PerformanceConfig @{} `
                -FragmentLibDir $script:FragmentLibDir

            @($result.BootstrapFragment).Count | Should -Be 1
            @($result.NonBootstrapFragments).Count | Should -Be 0
            @($result.FragmentsToLoad).Count | Should -Be 1
            $result.FragmentsToLoad[0].BaseName | Should -Be 'bootstrap'
        }

        It 'Skips unknown load order override names and keeps remaining fragments' {
            $result = Initialize-FragmentDiscovery `
                -AllFragments $script:AllFragments `
                -LoadOrderOverride @('missing-fragment', '20-beta') `
                -FragmentLoadingModule $script:FragmentLoadingModule `
                -FragmentLoadingModuleExists $false `
                -PerformanceConfig @{} `
                -FragmentLibDir $script:FragmentLibDir

            $names = @($result.NonBootstrapFragments | ForEach-Object { $_.BaseName })
            $names[0] | Should -Be '20-beta'
            $names[1] | Should -Be '10-alpha'
        }

        It 'Leaves DisabledSet null when no disabled fragments are configured' {
            $result = Initialize-FragmentDiscovery `
                -AllFragments $script:AllFragments `
                -DisabledFragments $null `
                -FragmentLoadingModule $script:FragmentLoadingModule `
                -FragmentLoadingModuleExists $false `
                -PerformanceConfig @{} `
                -FragmentLibDir $script:FragmentLibDir

            $result.DisabledSet | Should -BeNullOrEmpty
        }

        It 'Uses alphabetical ordering when parallel loading is enabled' {
            $result = Initialize-FragmentDiscovery `
                -AllFragments $script:AllFragments `
                -EnableParallelLoading $true `
                -FragmentLoadingModule $script:FragmentLoadingModule `
                -FragmentLoadingModuleExists $true `
                -PerformanceConfig @{ batchLoad = $true } `
                -FragmentLibDir $script:FragmentLibDir

            $names = @($result.NonBootstrapFragments | ForEach-Object { $_.BaseName })
            $names[0] | Should -Be '10-alpha'
            $names[1] | Should -Be '20-beta'
        }
    }
}
