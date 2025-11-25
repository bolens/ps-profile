<#
tests/unit/library-fragment-loading.tests.ps1

.SYNOPSIS
    Unit tests for FragmentLoading.psm1 module functions.
#>

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    # Import PathResolution first
    $pathResolutionModulePath = Get-TestPath -RelativePath 'scripts\lib\PathResolution.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction Stop

    # Import FileContent if available
    $fileContentModulePath = Get-TestPath -RelativePath 'scripts\lib\FileContent.psm1' -StartPath $PSScriptRoot -ErrorAction SilentlyContinue
    if ($fileContentModulePath) {
        Import-Module $fileContentModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }

    # Import the FragmentLoading module
    $fragmentLoadingPath = Get-TestPath -RelativePath 'scripts\lib\FragmentLoading.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentLoadingPath -DisableNameChecking -ErrorAction Stop

    # Get test data directory
    $testDataDir = Join-Path $PSScriptRoot '..' 'test-data'
    if (-not (Test-Path $testDataDir)) {
        New-Item -Path $testDataDir -ItemType Directory -Force | Out-Null
    }
}

Describe 'Get-FragmentDependencies' {
    Context 'When fragment has no dependencies' {
        It 'Returns empty array' {
            $tempFragment = Join-Path $testDataDir 'fragment-no-deps.ps1'
            Set-Content -Path $tempFragment -Value @'
# Test fragment with no dependencies
Write-Host "Test"
'@

            $deps = Get-FragmentDependencies -FragmentFile $tempFragment
            $deps | Should -Be @()

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'When fragment uses #Requires -Fragment syntax' {
        It 'Parses dependencies correctly' {
            $tempFragment = Join-Path $testDataDir 'fragment-requires.ps1'
            Set-Content -Path $tempFragment -Value @'
#Requires -Fragment '00-bootstrap'
#Requires -Fragment '01-env'
# Test fragment
Write-Host "Test"
'@

            $deps = Get-FragmentDependencies -FragmentFile $tempFragment
            $deps | Should -Contain '00-bootstrap'
            $deps | Should -Contain '01-env'
            $deps.Count | Should -Be 2

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'When fragment uses Dependencies: comment syntax' {
        It 'Parses dependencies correctly' {
            $tempFragment = Join-Path $testDataDir 'fragment-deps-comment.ps1'
            Set-Content -Path $tempFragment -Value @'
# Dependencies: 00-bootstrap, 01-env, 05-utilities
# Test fragment
Write-Host "Test"
'@

            $deps = Get-FragmentDependencies -FragmentFile $tempFragment
            $deps | Should -Contain '00-bootstrap'
            $deps | Should -Contain '01-env'
            $deps | Should -Contain '05-utilities'
            $deps.Count | Should -Be 3

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Get-FragmentLoadOrder' {
    Context 'When fragments have dependencies' {
        It 'Sorts fragments in dependency order' {
            $tempDir = Join-Path $testDataDir 'fragment-load-order-test'
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Recurse -Force
            }
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

            # Create test fragments
            # Fragment A depends on B
            Set-Content -Path (Join-Path $tempDir '10-fragment-a.ps1') -Value @'
#Requires -Fragment '20-fragment-b'
'@

            # Fragment B has no dependencies
            Set-Content -Path (Join-Path $tempDir '20-fragment-b.ps1') -Value @'
# No dependencies
'@

            # Fragment C depends on B
            Set-Content -Path (Join-Path $tempDir '30-fragment-c.ps1') -Value @'
#Requires -Fragment '20-fragment-b'
'@

            $fragments = Get-ChildItem -Path $tempDir -Filter '*.ps1' | Sort-Object Name

            $sorted = Get-FragmentLoadOrder -FragmentFiles $fragments

            # B should come before A and C
            $bIndex = [array]::IndexOf($sorted.BaseName, '20-fragment-b')
            $aIndex = [array]::IndexOf($sorted.BaseName, '10-fragment-a')
            $cIndex = [array]::IndexOf($sorted.BaseName, '30-fragment-c')

            $bIndex | Should -BeLessThan $aIndex
            $bIndex | Should -BeLessThan $cIndex

            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'When fragments are disabled' {
        It 'Excludes disabled fragments from result' {
            $tempDir = Join-Path $testDataDir 'fragment-disabled-test'
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Recurse -Force
            }
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

            Set-Content -Path (Join-Path $tempDir '10-fragment.ps1') -Value '# Test'
            Set-Content -Path (Join-Path $tempDir '20-fragment.ps1') -Value '# Test'

            $fragments = Get-ChildItem -Path $tempDir -Filter '*.ps1'
            $sorted = Get-FragmentLoadOrder -FragmentFiles $fragments -DisabledFragments @('20-fragment')

            $sorted.BaseName | Should -Not -Contain '20-fragment'
            $sorted.BaseName | Should -Contain '10-fragment'

            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Get-FragmentTiers' {
    It 'Groups fragments by tier correctly' {
        $tempDir = Join-Path $testDataDir 'fragment-tiers-test'
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

        # Create fragments in different tiers
        Set-Content -Path (Join-Path $tempDir '05-fragment.ps1') -Value '# Tier 0'
        Set-Content -Path (Join-Path $tempDir '15-fragment.ps1') -Value '# Tier 1'
        Set-Content -Path (Join-Path $tempDir '35-fragment.ps1') -Value '# Tier 2'
        Set-Content -Path (Join-Path $tempDir '75-fragment.ps1') -Value '# Tier 3'

        $fragments = Get-ChildItem -Path $tempDir -Filter '*.ps1'
        $tiers = Get-FragmentTiers -FragmentFiles $fragments

        $tiers.Tier0.BaseName | Should -Contain '05-fragment'
        $tiers.Tier1.BaseName | Should -Contain '15-fragment'
        $tiers.Tier2.BaseName | Should -Contain '35-fragment'
        $tiers.Tier3.BaseName | Should -Contain '75-fragment'

        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Excludes bootstrap when ExcludeBootstrap is specified' {
        $tempDir = Join-Path $testDataDir 'fragment-tiers-bootstrap-test'
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

        Set-Content -Path (Join-Path $tempDir '00-bootstrap.ps1') -Value '# Bootstrap'
        Set-Content -Path (Join-Path $tempDir '05-fragment.ps1') -Value '# Tier 0'

        $fragments = Get-ChildItem -Path $tempDir -Filter '*.ps1'
        $tiers = Get-FragmentTiers -FragmentFiles $fragments -ExcludeBootstrap

        $tiers.Tier0.BaseName | Should -Not -Contain '00-bootstrap'
        $tiers.Tier0.BaseName | Should -Contain '05-fragment'

        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

