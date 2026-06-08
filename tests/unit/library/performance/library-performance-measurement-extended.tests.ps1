<#
tests/unit/library-performance-measurement-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Measure-Operation timing and failure handling.
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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'core' 'Logging.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $libPath 'performance' 'PerformanceMeasurement.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module PerformanceMeasurement, Logging -ErrorAction SilentlyContinue -Force
}

Describe 'PerformanceMeasurement extended scenarios' {
    Context 'Measure-Operation' {
        It 'Does not throw when the measured script block fails' {
            { Measure-Operation -ScriptBlock { throw 'measurement failure' } -OperationName 'FailingOp' } |
                Should -Not -Throw
        }

        It 'Captures failure details without losing the operation name' {
            $result = Measure-Operation -ScriptBlock { throw 'measurement failure' } -OperationName 'NamedFailure'

            $result.Success | Should -Be $false
            $result.OperationName | Should -Be 'NamedFailure'
            $result.ErrorMessage | Should -Match 'measurement failure'
        }

        It 'Returns ISO8601 timestamps with EndTime after StartTime' {
            $result = Measure-Operation -ScriptBlock { Start-Sleep -Milliseconds 10 } -OperationName 'TimingCheck'

            $start = [DateTime]::Parse($result.StartTime)
            $end = [DateTime]::Parse($result.EndTime)
            $end | Should -BeGreaterOrEqual $start
        }

        It 'Returns metrics when LogMetrics is enabled' {
            $result = Measure-Operation -ScriptBlock { 'done' } -OperationName 'LoggedOp' -LogMetrics

            $result.OperationName | Should -Be 'LoggedOp'
            $result.Success | Should -Be $true
            $result.DurationMs | Should -BeGreaterOrEqual 0
        }

        It 'Reports zero or positive duration for instantaneous operations' {
            $result = Measure-Operation -ScriptBlock { $null } -OperationName 'InstantOp'

            $result.DurationMs | Should -BeGreaterOrEqual 0
        }
    }
}
