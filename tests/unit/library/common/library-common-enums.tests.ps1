<#
tests/unit/library-common-enums.tests.ps1

.SYNOPSIS
    Unit tests for CommonEnums module type registration and shared enum values.
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

AfterAll {
    Remove-Module CommonEnums -ErrorAction SilentlyContinue -Force
}

Describe 'CommonEnums Module Functions' {
    Context 'Add-CommonEnumType' {
        It 'Exports Add-CommonEnumType function' {
            Get-Command Add-CommonEnumType -ErrorAction Stop | Should -Not -BeNullOrEmpty
        }

        It 'Registers a new enum type when it does not exist' {
            { Add-CommonEnumType -Name 'TestBaseEnumSample' -Definition @'
public enum TestBaseEnumSample {
    One = 1,
    Two = 2
}
'@ } | Should -Not -Throw

            [TestBaseEnumSample]::One | Should -Be 1
            [TestBaseEnumSample]::Two | Should -Be 2
        }
    }

    Context 'FileSystemPathType enum' {
        It 'Defines Any, File, and Directory values' {
            [FileSystemPathType]::Any | Should -Be 0
            [FileSystemPathType]::File | Should -Be 1
            [FileSystemPathType]::Directory | Should -Be 2
        }
    }

    Context 'LogLevel enum' {
        It 'Defines Debug through Error values' {
            [LogLevel]::Debug | Should -Be 0
            [LogLevel]::Info | Should -Be 1
            [LogLevel]::Warning | Should -Be 2
            [LogLevel]::Error | Should -Be 3
        }
    }

    Context 'ExitCode enum' {
        It 'Defines standard and test-runner exit codes' {
            [ExitCode]::Success | Should -Be 0
            [ExitCode]::ValidationFailure | Should -Be 1
            [ExitCode]::SetupError | Should -Be 2
            [ExitCode]::OtherError | Should -Be 3
            [ExitCode]::TestFailure | Should -Be 4
            [ExitCode]::CoverageFailure | Should -Be 6
            [ExitCode]::NoTestsFound | Should -Be 7
        }
    }

    Context 'TestSuite enum' {
        It 'Defines All, Unit, Integration, and Performance values' {
            [TestSuite]::All | Should -Be 0
            [TestSuite]::Unit | Should -Be 1
            [TestSuite]::Integration | Should -Be 2
            [TestSuite]::Performance | Should -Be 3
        }
    }

    Context 'FragmentTier enum' {
        It 'Defines tier ordering from core to optional' {
            [FragmentTier]::core | Should -Be 0
            [FragmentTier]::essential | Should -Be 1
            [FragmentTier]::standard | Should -Be 2
            [FragmentTier]::optional | Should -Be 3
        }
    }

    Context 'PesterVerbosity and VerbosityLevel enums' {
        It 'Defines matching verbosity levels' {
            [PesterVerbosity]::None | Should -Be 0
            [PesterVerbosity]::Detailed | Should -Be 3
            [VerbosityLevel]::None | Should -Be 0
            [VerbosityLevel]::Detailed | Should -Be 3
        }
    }

    Context 'Output and report format enums' {
        It 'Defines OutputFormat values' {
            [OutputFormat]::Table | Should -Be 0
            [OutputFormat]::Json | Should -Be 1
            [OutputFormat]::Csv | Should -Be 2
        }

        It 'Defines ReportFormat values' {
            [ReportFormat]::Summary | Should -Be 0
            [ReportFormat]::Technical | Should -Be 3
        }

        It 'Defines TestReportFormat values' {
            [TestReportFormat]::JSON | Should -Be 0
            [TestReportFormat]::Markdown | Should -Be 2
        }
    }

    Context 'Database and severity enums' {
        It 'Defines DatabaseAction values' {
            [DatabaseAction]::health | Should -Be 0
            [DatabaseAction]::statistics | Should -Be 4
        }

        It 'Defines DatabaseStatus values' {
            [DatabaseStatus]::Missing | Should -Be 0
            [DatabaseStatus]::Healthy | Should -Be 2
        }

        It 'Defines SeverityLevel values' {
            [SeverityLevel]::Error | Should -Be 0
            [SeverityLevel]::Information | Should -Be 2
        }
    }

    Context 'FragmentCacheType enum' {
        It 'Defines content, ast, and all cache types' {
            [FragmentCacheType]::content | Should -Be 0
            [FragmentCacheType]::ast | Should -Be 1
            [FragmentCacheType]::all | Should -Be 2
        }
    }
}
