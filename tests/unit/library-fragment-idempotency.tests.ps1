<#
tests/unit/library-fragment-idempotency.tests.ps1

.SYNOPSIS
    Unit tests for FragmentIdempotency.psm1 module functions.
#>

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    # Import the FragmentIdempotency module
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts\lib\fragment\FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop
}

Describe 'Test-FragmentLoaded' {
    Context 'When fragment is not loaded' {
        It 'Returns false' {
            # Ensure fragment is not loaded
            $fragmentName = 'TestFragmentNotLoaded'
            Clear-FragmentLoaded -FragmentName $fragmentName -ErrorAction SilentlyContinue

            $loaded = Test-FragmentLoaded -FragmentName $fragmentName
            $loaded | Should -Be $false
        }
    }

    Context 'When fragment is loaded' {
        It 'Returns true' {
            $fragmentName = 'TestFragmentLoaded'
            Set-FragmentLoaded -FragmentName $fragmentName

            $loaded = Test-FragmentLoaded -FragmentName $fragmentName
            $loaded | Should -Be $true

            # Cleanup
            Clear-FragmentLoaded -FragmentName $fragmentName
        }
    }

    Context 'When fragment name is empty' {
        It 'Returns false' {
            $loaded = Test-FragmentLoaded -FragmentName ''
            $loaded | Should -Be $false

            # When $null is passed to a [string] parameter, PowerShell converts it to empty string
            # So we test with explicit empty string and also test the function's null handling
            $loaded = Test-FragmentLoaded -FragmentName ([string]$null)
            $loaded | Should -Be $false
        }
    }
}

Describe 'Set-FragmentLoaded' {
    It 'Sets the loaded state for a fragment' {
        $fragmentName = 'TestFragmentSetLoaded'
        Clear-FragmentLoaded -FragmentName $fragmentName -ErrorAction SilentlyContinue

        Set-FragmentLoaded -FragmentName $fragmentName

        $variableName = "${fragmentName}Loaded"
        $variable = Get-Variable -Name $variableName -Scope Global -ErrorAction SilentlyContinue
        $variable | Should -Not -BeNullOrEmpty
        $variable.Value | Should -Be $true

        # Cleanup
        Clear-FragmentLoaded -FragmentName $fragmentName
    }
}

Describe 'Clear-FragmentLoaded' {
    It 'Clears the loaded state for a fragment' {
        $fragmentName = 'TestFragmentClearLoaded'
        Set-FragmentLoaded -FragmentName $fragmentName

        Clear-FragmentLoaded -FragmentName $fragmentName

        $variableName = "${fragmentName}Loaded"
        $variable = Get-Variable -Name $variableName -Scope Global -ErrorAction SilentlyContinue
        $variable | Should -BeNullOrEmpty
    }
}

Describe 'Get-FragmentIdempotencyCheck' {
    It 'Returns a script block that checks fragment loaded state' {
        $fragmentName = 'TestFragmentIdempotencyCheck'
        Clear-FragmentLoaded -FragmentName $fragmentName -ErrorAction SilentlyContinue

        $checkScript = Get-FragmentIdempotencyCheck -FragmentName $fragmentName

        $checkScript | Should -Not -BeNullOrEmpty
        $checkScript | Should -BeOfType [scriptblock]

        # Test the script block
        $shouldSkip = & $checkScript
        $shouldSkip | Should -Be $false

        Set-FragmentLoaded -FragmentName $fragmentName
        $shouldSkip = & $checkScript
        $shouldSkip | Should -Be $true

        # Cleanup
        Clear-FragmentLoaded -FragmentName $fragmentName
    }
}

