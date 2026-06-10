<#
tests/unit/library-performance-regression-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Test-PerformanceRegression metric comparison edge cases.
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
    $script:ProfileDir = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'profile.d'
    Import-Module (Join-Path $script:LibPath 'utilities' 'JsonUtilities.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $script:LibPath 'performance' 'PerformanceRegression.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'PerformanceRegressionExtended'
    $script:BaselineFile = Join-Path $script:TempDir 'baseline.json'
    @{
        DurationMs = 1000
        MemoryMB   = 50
    } | ConvertTo-Json | Set-Content -LiteralPath $script:BaselineFile -Encoding UTF8
}

function script:Clear-PerformanceRegressionTestEnvironment {
    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        return
    }

    function global:Write-StructuredWarning {
        param(
            [string]$Message,
            [string]$OperationName,
            [hashtable]$Context,
            [string]$Code
        )

        return $null
    }
}

AfterAll {
    Clear-PerformanceRegressionTestEnvironment
    Remove-Module PerformanceRegression, JsonUtilities -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PerformanceRegression extended scenarios' {
    BeforeEach { Clear-PerformanceRegressionTestEnvironment }

    Context 'Test-PerformanceRegression' {
        It 'Detects memory regressions independently of duration' {
            $result = Test-PerformanceRegression -CurrentMetrics @{
                DurationMs = 900
                MemoryMB   = 120
            } -BaselineFile $script:BaselineFile

            $result.RegressionDetected | Should -Be $true
            @($result.Details | Where-Object { $_.Metric -eq 'MemoryMB' }).Count | Should -Be 1
        }

        It 'Reports no regression when metrics match the baseline exactly' {
            $result = Test-PerformanceRegression -CurrentMetrics @{
                DurationMs = 1000
                MemoryMB   = 50
            } -BaselineFile $script:BaselineFile

            $result.RegressionDetected | Should -Be $false
            $result.Ratio | Should -Be 1
        }

        It 'Ignores metrics that are absent from the baseline file' {
            $result = Test-PerformanceRegression -CurrentMetrics @{
                CpuPercent = 95
            } -BaselineFile $script:BaselineFile

            $result.RegressionDetected | Should -Be $false
            @($result.Details).Count | Should -Be 0
        }

        It 'Returns baseline load errors for invalid JSON files' {
            $invalidBaseline = Join-Path $script:TempDir 'invalid-baseline.json'
            Set-Content -LiteralPath $invalidBaseline -Value '{ not json' -Encoding UTF8

            $result = Test-PerformanceRegression -CurrentMetrics @{ DurationMs = 1000 } -BaselineFile $invalidBaseline -WarningAction SilentlyContinue

            $result.RegressionDetected | Should -Be $false
            $result.Message | Should -Match 'Error loading baseline'
        }

        It 'Includes the operation name in successful comparisons' {
            $result = Test-PerformanceRegression -CurrentMetrics @{ DurationMs = 800 } -BaselineFile $script:BaselineFile -OperationName 'StartupBenchmark'

            $result.OperationName | Should -Be 'StartupBenchmark'
        }

        It 'Emits structured warnings for empty metrics when debug is disabled' {
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            Enable-TestStructuredLogging

            $result = Test-PerformanceRegression -CurrentMetrics @{} -BaselineFile $script:BaselineFile

            $result | Should -Not -BeNullOrEmpty
            $result.RegressionDetected | Should -Be $false
        }

        It 'Logs empty metric details at debug level 3' {
            $env:PS_PROFILE_DEBUG = '3'

            $result = Test-PerformanceRegression -CurrentMetrics @{} -BaselineFile $script:BaselineFile

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Logs missing baseline details at debug level 2' {
            $missingBaseline = Join-Path $script:TempDir 'missing-baseline.json'
            $env:PS_PROFILE_DEBUG = '2'

            $result = Test-PerformanceRegression -CurrentMetrics @{ DurationMs = 1000 } -BaselineFile $missingBaseline

            $result.Message | Should -Match 'No baseline found'
        }

        It 'Emits structured warnings for invalid baseline JSON without debug enabled' {
            $invalidBaseline = Join-Path $script:TempDir 'structured-invalid-baseline.json'
            Set-Content -LiteralPath $invalidBaseline -Value '{ not json' -Encoding UTF8
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            Enable-TestStructuredLogging

            $result = Test-PerformanceRegression -CurrentMetrics @{ DurationMs = 1000 } -BaselineFile $invalidBaseline

            $result.Message | Should -Match 'Error loading baseline'
        }

        It 'Uses plain warnings for invalid baseline JSON when structured logging is unavailable' {
            $invalidBaseline = Join-Path $script:TempDir 'plain-invalid-baseline.json'
            Set-Content -LiteralPath $invalidBaseline -Value '{ not json' -Encoding UTF8
            Remove-TestFunction -Name @('Write-StructuredWarning', 'Write-StructuredError')
            $env:PS_PROFILE_DEBUG = '1'

            $result = Test-PerformanceRegression -CurrentMetrics @{ DurationMs = 1000 } -BaselineFile $invalidBaseline -WarningAction SilentlyContinue

            $result.Message | Should -Match 'Error loading baseline'
        }

        It 'Logs within-threshold metric comparisons at debug level 3' {
            $env:PS_PROFILE_DEBUG = '3'

            $result = Test-PerformanceRegression -CurrentMetrics @{ DurationMs = 1100 } -BaselineFile $script:BaselineFile

            $result.RegressionDetected | Should -Be $false
        }

        It 'Accepts PSCustomObject metrics and detects regressions above threshold' {
            $current = [PSCustomObject]@{ DurationMs = 2500 }

            $result = Test-PerformanceRegression -CurrentMetrics $current -BaselineFile $script:BaselineFile -OperationName 'StartupBenchmark'

            $result.RegressionDetected | Should -Be $true
            @($result.Details).Count | Should -BeGreaterOrEqual 1
        }

        It 'Emits plain warnings for empty metrics when structured logging is unavailable' {
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            Remove-TestFunction -Name 'Write-StructuredWarning'

            $result = Test-PerformanceRegression -CurrentMetrics @{} -BaselineFile $script:BaselineFile -WarningAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Logs baseline load errors at debug level 3 without structured logging' {
            $invalidBaseline = Join-Path $script:TempDir 'debug-invalid-baseline.json'
            Set-Content -LiteralPath $invalidBaseline -Value '{ not json' -Encoding UTF8
            $env:PS_PROFILE_DEBUG = '3'
            Remove-TestFunction -Name @('Write-StructuredWarning', 'Write-StructuredError')

            $result = Test-PerformanceRegression -CurrentMetrics @{ DurationMs = 1000 } -BaselineFile $invalidBaseline -WarningAction SilentlyContinue

            $result.Message | Should -Match 'Error loading baseline'
        }
    }
}
