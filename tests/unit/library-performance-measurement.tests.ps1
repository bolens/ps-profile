. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    
    # Import Logging module first (dependency)
    $loggingPath = Join-Path $script:LibPath 'core' 'Logging.psm1'
    if (Test-Path $loggingPath) {
        Import-Module $loggingPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Import the module under test
    $script:PerformanceMeasurementPath = Join-Path $script:LibPath 'performance' 'PerformanceMeasurement.psm1'
    Import-Module $script:PerformanceMeasurementPath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module PerformanceMeasurement -ErrorAction SilentlyContinue -Force
    Remove-Module Logging -ErrorAction SilentlyContinue -Force
}

Describe 'PerformanceMeasurement Module Functions' {
    Context 'Measure-Operation' {
        It 'Measures operation execution time' {
            $result = Measure-Operation -ScriptBlock { Start-Sleep -Milliseconds 50 }
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Returns DurationMs property' {
            $result = Measure-Operation -ScriptBlock { Start-Sleep -Milliseconds 50 }
            $result.DurationMs | Should -BeGreaterThan 0
            $result.DurationMs | Should -BeOfType [double]
        }

        It 'Returns OperationName property' {
            $result = Measure-Operation -ScriptBlock { Write-Host 'test' } -OperationName 'TestOperation'
            $result.OperationName | Should -Be 'TestOperation'
        }

        It 'Uses default OperationName when not specified' {
            $result = Measure-Operation -ScriptBlock { Write-Host 'test' }
            $result.OperationName | Should -Be 'Operation'
        }

        It 'Returns StartTime and EndTime' {
            $result = Measure-Operation -ScriptBlock { Write-Host 'test' }
            $result.StartTime | Should -Not -BeNullOrEmpty
            $result.EndTime | Should -Not -BeNullOrEmpty
        }

        It 'Returns Success property' {
            $result = Measure-Operation -ScriptBlock { Write-Host 'test' }
            $result.Success | Should -Be $true
        }

        It 'Returns Success false when operation throws' {
            $result = Measure-Operation -ScriptBlock { throw "Test error" } -ErrorAction SilentlyContinue
            $result.Success | Should -Be $false
        }

        It 'Returns ErrorMessage when operation fails' {
            $result = Measure-Operation -ScriptBlock { throw "Test error" } -ErrorAction SilentlyContinue
            $result.ErrorMessage | Should -Not -BeNullOrEmpty
            $result.ErrorMessage | Should -Match 'Test error'
        }

        It 'Logs metrics when LogMetrics specified' {
            # Should not throw when logging
            { Measure-Operation -ScriptBlock { Write-Host 'test' } -LogMetrics } | Should -Not -Throw
        }

        It 'Handles fast operations' {
            $result = Measure-Operation -ScriptBlock { $null }
            $result.DurationMs | Should -BeGreaterOrEqual 0
        }

        It 'Handles operations that return values' {
            $result = Measure-Operation -ScriptBlock { return 42 }
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }

        It 'Rounds duration to 2 decimal places' {
            $result = Measure-Operation -ScriptBlock { Start-Sleep -Milliseconds 10 }
            $durationString = $result.DurationMs.ToString()
            # Check that it's rounded (no more than 2 decimal places)
            if ($durationString -match '\.') {
                $decimalPlaces = ($durationString -split '\.')[1].Length
                $decimalPlaces | Should -BeLessOrEqual 2
            }
        }
    }
}

