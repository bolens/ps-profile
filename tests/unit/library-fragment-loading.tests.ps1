<#
tests/unit/library-fragment-loading.tests.ps1

.SYNOPSIS
    Unit tests for FragmentLoading.psm1 module functions.
#>

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    # Import PathResolution first (use SilentlyContinue to avoid duplicate ErrorAction issues)
    $pathResolutionModulePath = Get-TestPath -RelativePath 'scripts\lib\path\PathResolution.psm1' -StartPath $PSScriptRoot -EnsureExists
    if ($pathResolutionModulePath -and (Test-Path -LiteralPath $pathResolutionModulePath)) {
        Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }

    # Import FileContent if available
    $fileContentModulePath = Get-TestPath -RelativePath 'scripts\lib\file\FileContent.psm1' -StartPath $PSScriptRoot -ErrorAction SilentlyContinue
    if ($fileContentModulePath -and (Test-Path -LiteralPath $fileContentModulePath)) {
        Import-Module $fileContentModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }

    # Import the FragmentLoading module
    $fragmentLoadingPath = Get-TestPath -RelativePath 'scripts\lib\fragment\FragmentLoading.psm1' -StartPath $PSScriptRoot -EnsureExists
    if ($fragmentLoadingPath -and (Test-Path -LiteralPath $fragmentLoadingPath)) {
        try {
            Import-Module $fragmentLoadingPath -DisableNameChecking -ErrorAction Stop -Force
        }
        catch {
            # If import fails, try to get more details
            Write-Warning "Failed to import FragmentLoading module: $($_.Exception.Message)"
            Write-Warning "Error details: $($_.Exception.GetType().FullName)"
            throw
        }
    }
    else {
        throw "FragmentLoading module not found at: $fragmentLoadingPath"
    }

    # Verify required functions are available
    $missingFunctions = @()
    if (-not (Get-Command Get-FragmentDependencies -ErrorAction SilentlyContinue)) {
        $missingFunctions += 'Get-FragmentDependencies'
    }
    if (-not (Get-Command Get-FragmentTier -ErrorAction SilentlyContinue)) {
        $missingFunctions += 'Get-FragmentTier'
    }
    if (-not (Get-Command Get-FragmentTiers -ErrorAction SilentlyContinue)) {
        $missingFunctions += 'Get-FragmentTiers'
    }
    if (-not (Get-Command Get-FragmentLoadOrder -ErrorAction SilentlyContinue)) {
        $missingFunctions += 'Get-FragmentLoadOrder'
    }
    
    if ($missingFunctions.Count -gt 0) {
        $availableFunctions = Get-Command -Module FragmentLoading -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
        throw "Required functions not available after importing FragmentLoading module. Missing: $($missingFunctions -join ', '). Available: $($availableFunctions -join ', ')"
    }

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
#Requires -Fragment 'bootstrap'
#Requires -Fragment 'env'
# Test fragment
Write-Host "Test"
'@

            $deps = Get-FragmentDependencies -FragmentFile $tempFragment
            $deps | Should -Contain 'bootstrap'
            $deps | Should -Contain 'env'
            $deps.Count | Should -Be 2

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'When fragment uses Dependencies: comment syntax' {
        It 'Parses dependencies correctly' {
            $tempFragment = Join-Path $testDataDir 'fragment-deps-comment.ps1'
            Set-Content -Path $tempFragment -Value @'
# Dependencies: bootstrap, env, utilities
# Test fragment
Write-Host "Test"
'@

            $deps = Get-FragmentDependencies -FragmentFile $tempFragment
            $deps | Should -Contain 'bootstrap'
            $deps | Should -Contain 'env'
            $deps | Should -Contain 'utilities'
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

Describe 'Get-FragmentTier' {
    Context 'When fragment has explicit tier declaration' {
        It 'Parses core tier correctly' {
            $tempFragment = Join-Path $testDataDir 'fragment-tier-core.ps1'
            Set-Content -Path $tempFragment -Value @'
# Tier: core
# Test fragment
Write-Host "Test"
'@

            $tier = Get-FragmentTier -FragmentFile $tempFragment
            $tier | Should -Be 'core'

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }

        It 'Parses essential tier correctly' {
            $tempFragment = Join-Path $testDataDir 'fragment-tier-essential.ps1'
            Set-Content -Path $tempFragment -Value @'
# Tier: essential
# Test fragment
Write-Host "Test"
'@

            $tier = Get-FragmentTier -FragmentFile $tempFragment
            $tier | Should -Be 'essential'

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }

        It 'Parses standard tier correctly' {
            $tempFragment = Join-Path $testDataDir 'fragment-tier-standard.ps1'
            Set-Content -Path $tempFragment -Value @'
# Tier: standard
# Test fragment
Write-Host "Test"
'@

            $tier = Get-FragmentTier -FragmentFile $tempFragment
            $tier | Should -Be 'standard'

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }

        It 'Parses optional tier correctly' {
            $tempFragment = Join-Path $testDataDir 'fragment-tier-optional.ps1'
            Set-Content -Path $tempFragment -Value @'
# Tier: optional
# Test fragment
Write-Host "Test"
'@

            $tier = Get-FragmentTier -FragmentFile $tempFragment
            $tier | Should -Be 'optional'

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }

        It 'Is case-insensitive' {
            $tempFragment = Join-Path $testDataDir 'fragment-tier-case.ps1'
            Set-Content -Path $tempFragment -Value @'
# TIER: CORE
# Test fragment
Write-Host "Test"
'@

            $tier = Get-FragmentTier -FragmentFile $tempFragment
            $tier | Should -Be 'core'

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'When fragment has numeric prefix (backward compatibility)' {
        It 'Maps 00-09 to core tier' {
            $tempFragment = Join-Path $testDataDir '05-fragment.ps1'
            Set-Content -Path $tempFragment -Value '# Test fragment'

            $tier = Get-FragmentTier -FragmentFile $tempFragment
            $tier | Should -Be 'core'

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }

        It 'Maps 10-29 to essential tier' {
            $tempFragment = Join-Path $testDataDir '15-fragment.ps1'
            Set-Content -Path $tempFragment -Value '# Test fragment'

            $tier = Get-FragmentTier -FragmentFile $tempFragment
            $tier | Should -Be 'essential'

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }

        It 'Maps 30-69 to standard tier' {
            $tempFragment = Join-Path $testDataDir '35-fragment.ps1'
            Set-Content -Path $tempFragment -Value '# Test fragment'

            $tier = Get-FragmentTier -FragmentFile $tempFragment
            $tier | Should -Be 'standard'

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }

        It 'Maps 70-99 to optional tier' {
            $tempFragment = Join-Path $testDataDir '75-fragment.ps1'
            Set-Content -Path $tempFragment -Value '# Test fragment'

            $tier = Get-FragmentTier -FragmentFile $tempFragment
            $tier | Should -Be 'optional'

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }

        It 'Recognizes bootstrap fragment as core' {
            $tempFragment = Join-Path $testDataDir 'bootstrap.ps1'
            Set-Content -Path $tempFragment -Value '# Bootstrap fragment'

            $tier = Get-FragmentTier -FragmentFile $tempFragment
            $tier | Should -Be 'core'

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }

        It 'Recognizes named bootstrap fragment as core' {
            $tempFragment = Join-Path $testDataDir 'bootstrap.ps1'
            Set-Content -Path $tempFragment -Value '# Bootstrap fragment'

            $tier = Get-FragmentTier -FragmentFile $tempFragment
            $tier | Should -Be 'core'

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'When fragment has no tier declaration' {
        It 'Defaults to optional tier' {
            $tempFragment = Join-Path $testDataDir 'fragment-no-tier.ps1'
            Set-Content -Path $tempFragment -Value @'
# Test fragment with no tier declaration
Write-Host "Test"
'@

            $tier = Get-FragmentTier -FragmentFile $tempFragment
            $tier | Should -Be 'optional'

            Remove-Item $tempFragment -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'When fragment file does not exist' {
        It 'Returns optional tier' {
            $nonExistentFile = Join-Path $testDataDir 'nonexistent-fragment.ps1'
            $tier = Get-FragmentTier -FragmentFile $nonExistentFile
            $tier | Should -Be 'optional'
        }
    }
}

Describe 'Get-FragmentTiers' {
    Context 'When fragments use numeric prefixes (backward compatibility)' {
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
    }

    Context 'When fragments use explicit tier declarations' {
        It 'Groups fragments by explicit tier declarations' {
            $tempDir = Join-Path $testDataDir 'fragment-tiers-explicit-test'
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Recurse -Force
            }
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

            # Create fragments with explicit tier declarations
            Set-Content -Path (Join-Path $tempDir 'core-fragment.ps1') -Value @'
# Tier: core
# Core fragment
'@
            Set-Content -Path (Join-Path $tempDir 'essential-fragment.ps1') -Value @'
# Tier: essential
# Essential fragment
'@
            Set-Content -Path (Join-Path $tempDir 'standard-fragment.ps1') -Value @'
# Tier: standard
# Standard fragment
'@
            Set-Content -Path (Join-Path $tempDir 'optional-fragment.ps1') -Value @'
# Tier: optional
# Optional fragment
'@

            $fragments = Get-ChildItem -Path $tempDir -Filter '*.ps1'
            $tiers = Get-FragmentTiers -FragmentFiles $fragments

            $tiers.Tier0.BaseName | Should -Contain 'core-fragment'
            $tiers.Tier1.BaseName | Should -Contain 'essential-fragment'
            $tiers.Tier2.BaseName | Should -Contain 'standard-fragment'
            $tiers.Tier3.BaseName | Should -Contain 'optional-fragment'

            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'When fragments mix explicit declarations and numeric prefixes' {
        It 'Handles mixed fragment types correctly' {
            $tempDir = Join-Path $testDataDir 'fragment-tiers-mixed-test'
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Recurse -Force
            }
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

            # Mix of numbered and named fragments
            Set-Content -Path (Join-Path $tempDir '05-numbered.ps1') -Value '# Numbered fragment'
            Set-Content -Path (Join-Path $tempDir 'named-core.ps1') -Value @'
# Tier: core
# Named fragment
'@
            Set-Content -Path (Join-Path $tempDir '15-numbered.ps1') -Value '# Numbered fragment'
            Set-Content -Path (Join-Path $tempDir 'named-essential.ps1') -Value @'
# Tier: essential
# Named fragment
'@

            $fragments = Get-ChildItem -Path $tempDir -Filter '*.ps1'
            $tiers = Get-FragmentTiers -FragmentFiles $fragments

            # Both numbered and named core fragments should be in Tier0
            $tiers.Tier0.BaseName | Should -Contain '05-numbered'
            $tiers.Tier0.BaseName | Should -Contain 'named-core'
            # Both numbered and named essential fragments should be in Tier1
            $tiers.Tier1.BaseName | Should -Contain '15-numbered'
            $tiers.Tier1.BaseName | Should -Contain 'named-essential'

            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Excludes bootstrap when ExcludeBootstrap is specified' {
        $tempDir = Join-Path $testDataDir 'fragment-tiers-bootstrap-test'
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

        Set-Content -Path (Join-Path $tempDir 'bootstrap.ps1') -Value '# Bootstrap'
        Set-Content -Path (Join-Path $tempDir 'bootstrap.ps1') -Value @'
# Tier: core
# Bootstrap
'@
        Set-Content -Path (Join-Path $tempDir '05-fragment.ps1') -Value '# Tier 0'

        $fragments = Get-ChildItem -Path $tempDir -Filter '*.ps1'
        $tiers = Get-FragmentTiers -FragmentFiles $fragments -ExcludeBootstrap

        $tiers.Tier0.BaseName | Should -Not -Contain 'bootstrap'
        $tiers.Tier0.BaseName | Should -Not -Contain 'bootstrap'
        $tiers.Tier0.BaseName | Should -Contain '05-fragment'

        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

