<#
tests/unit/library-common-enums-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for CommonEnums type registration and enum values.
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
    $commonEnumsModule = Get-TestPath -RelativePath 'scripts\lib\core\CommonEnums.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $commonEnumsModule -DisableNameChecking -ErrorAction Stop -Global
}

Describe 'CommonEnums extended scenarios' {
    Context 'Add-CommonEnumType' {
        It 'Registers a custom enum type once' {
            { Add-CommonEnumType -Name 'TestPassEnumSample' -Definition @'
public enum TestPassEnumSample {
    Alpha = 0,
    Beta  = 1
}
'@ } | Should -Not -Throw

            [TestPassEnumSample]::Alpha | Should -Be 0
            [TestPassEnumSample]::Beta | Should -Be 1
        }

        It 'Is idempotent when the enum type already exists' {
            { Add-CommonEnumType -Name 'TestPassEnumSample' -Definition @'
public enum TestPassEnumSample {
    Alpha = 0,
    Beta  = 1
}
'@ } | Should -Not -Throw
        }
    }

    Context 'Shared enum values' {
        It 'Defines TestSuite values used by the test runner' {
            [TestSuite]::All | Should -Be 0
            [TestSuite]::Unit | Should -Be 1
            [TestSuite]::Integration | Should -Be 2
            [TestSuite]::Performance | Should -Be 3
        }

        It 'Defines ExitCode values including watch-mode cancellation' {
            [ExitCode]::Success | Should -Be 0
            [ExitCode]::ValidationFailure | Should -Be 1
            [ExitCode]::WatchModeCanceled | Should -Be 8
        }

        It 'Defines FragmentTier ordering from core to optional' {
            [FragmentTier]::core | Should -Be 0
            [FragmentTier]::essential | Should -Be 1
            [FragmentTier]::standard | Should -Be 2
            [FragmentTier]::optional | Should -Be 3
        }

        It 'Defines TestReportFormat values for report generation' {
            [TestReportFormat]::JSON | Should -Be 0
            [TestReportFormat]::HTML | Should -Be 1
            [TestReportFormat]::Markdown | Should -Be 2
        }
    }
}
