<#
tests/unit/library-fragment-idempotency-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for fragment idempotency state isolation and edge cases.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts\lib\fragment\FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -Force
}

AfterAll {
    Remove-Module FragmentIdempotency -ErrorAction SilentlyContinue -Force
}

Describe 'FragmentIdempotency extended scenarios' {
    AfterEach {
        Clear-FragmentLoaded -FragmentName 'ExtendedFragmentA' -ErrorAction SilentlyContinue
        Clear-FragmentLoaded -FragmentName 'ExtendedFragmentB' -ErrorAction SilentlyContinue
        Clear-FragmentLoaded -FragmentName 'ExtendedWhitespace' -ErrorAction SilentlyContinue
    }

    Context 'Set-FragmentLoaded and Test-FragmentLoaded' {
        It 'Ignores whitespace-only fragment names' {
            Set-FragmentLoaded -FragmentName '   '

            Test-FragmentLoaded -FragmentName '   ' | Should -Be $false
        }

        It 'Tracks multiple fragments independently' {
            Set-FragmentLoaded -FragmentName 'ExtendedFragmentA'

            Test-FragmentLoaded -FragmentName 'ExtendedFragmentA' | Should -Be $true
            Test-FragmentLoaded -FragmentName 'ExtendedFragmentB' | Should -Be $false
        }

        It 'Allows reloading after the loaded state is cleared' {
            Set-FragmentLoaded -FragmentName 'ExtendedFragmentA'
            Clear-FragmentLoaded -FragmentName 'ExtendedFragmentA'

            Test-FragmentLoaded -FragmentName 'ExtendedFragmentA' | Should -Be $false

            Set-FragmentLoaded -FragmentName 'ExtendedFragmentA'
            Test-FragmentLoaded -FragmentName 'ExtendedFragmentA' | Should -Be $true
        }
    }

    Context 'Clear-FragmentLoaded' {
        It 'Does not throw when clearing a fragment that was never loaded' {
            { Clear-FragmentLoaded -FragmentName 'ExtendedFragmentB' } | Should -Not -Throw
        }
    }

    Context 'Get-FragmentIdempotencyCheck' {
        It 'Returns independent script blocks per fragment name' {
            Clear-FragmentLoaded -FragmentName 'ExtendedFragmentA' -ErrorAction SilentlyContinue
            Clear-FragmentLoaded -FragmentName 'ExtendedFragmentB' -ErrorAction SilentlyContinue

            $checkA = Get-FragmentIdempotencyCheck -FragmentName 'ExtendedFragmentA'
            $checkB = Get-FragmentIdempotencyCheck -FragmentName 'ExtendedFragmentB'

            Set-FragmentLoaded -FragmentName 'ExtendedFragmentA'

            (& $checkA) | Should -Be $true
            (& $checkB) | Should -Be $false
        }
    }
}
