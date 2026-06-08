<#
tests/unit/profile-global-state-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for GlobalState debug helpers and initialization.
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
    $bootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap\GlobalState.ps1' -StartPath $PSScriptRoot -EnsureExists
    . $bootstrapPath
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    Remove-Item Env:\PS_PROFILE_VERBOSE_EXTERNAL_TOOLS -ErrorAction SilentlyContinue
}

Describe 'GlobalState extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        Remove-Item Env:\PS_PROFILE_VERBOSE_EXTERNAL_TOOLS -ErrorAction SilentlyContinue
    }

    Context 'Get-ProfileDebugLevel' {
        It 'Returns zero when PS_PROFILE_DEBUG is unset' {
            Get-ProfileDebugLevel | Should -Be 0
        }

        It 'Parses numeric debug levels from the environment' {
            $env:PS_PROFILE_DEBUG = '2'
            Get-ProfileDebugLevel | Should -Be 2
        }

        It 'Returns zero for non-numeric debug values' {
            $env:PS_PROFILE_DEBUG = 'verbose'
            Get-ProfileDebugLevel | Should -Be 0
        }
    }

    Context 'Test-EnvBool' {
        It 'Treats padded true values as enabled' {
            Test-EnvBool -Value '  TRUE  ' | Should -Be $true
        }

        It 'Treats false-like values as disabled' {
            Test-EnvBool -Value 'false' | Should -Be $false
            Test-EnvBool -Value '0' | Should -Be $false
        }
    }

    Context 'Bootstrap initialization' {
        It 'Marks bootstrap as initialized and creates core caches' {
            $global:PSProfileBootstrapInitialized | Should -Be $true
            $global:TestCachedCommandCache | Should -Not -BeNullOrEmpty
            $global:MissingToolWarnings | Should -Not -BeNullOrEmpty
        }
    }
}
