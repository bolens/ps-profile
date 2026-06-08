<#
tests/unit/library-parallel-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Invoke-Parallel pipeline and throttling behavior.
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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'parallel' 'Parallel.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module Parallel -ErrorAction SilentlyContinue -Force
}

Describe 'Parallel extended scenarios' {
    Context 'Invoke-Parallel' {
        It 'Accepts pipeline input across multiple batches' {
            $result = 1, 2, 3 | Invoke-Parallel -ScriptBlock { $_ * 10 }

            @($result).Count | Should -Be 3
            $result | Should -Contain 10
            $result | Should -Contain 20
            $result | Should -Contain 30
        }

        It 'Returns a single-element result collection for one input item' {
            $result = @(42) | Invoke-Parallel -ScriptBlock { $_ + 1 }

            @($result).Count | Should -Be 1
            @($result)[0] | Should -Be 43
        }

        It 'Invokes parameterized script blocks with explicit parameters' {
            $scriptBlock = { param($Value) "value:$Value" }
            $result = @(7, 8) | Invoke-Parallel -ScriptBlock $scriptBlock

            @($result).Count | Should -Be 2
            $result | Should -Contain 'value:7'
            $result | Should -Contain 'value:8'
        }

        It 'Uses processor defaults when ThrottleLimit is zero' {
            $result = @(1..4) | Invoke-Parallel -ScriptBlock { $_ } -ThrottleLimit 0

            @($result).Count | Should -Be 4
        }
    }
}
