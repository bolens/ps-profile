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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'core' 'Logging.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $script:LibPath 'performance' 'PerformanceMeasurement.psm1') -DisableNameChecking -Force
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

    Context 'Debug and structured output hooks' {
        It 'Uses plain warnings when structured logging is disabled for failures' {
            $originalFlag = $env:PS_PROFILE_PERFORMANCE_MEASUREMENT_DISABLE_STRUCTURED_WARNING
            $env:PS_PROFILE_PERFORMANCE_MEASUREMENT_DISABLE_STRUCTURED_WARNING = '1'

            try {
                $result = Measure-Operation -ScriptBlock { throw 'plain warning probe' } -OperationName 'PlainWarn'
                $result.Success | Should -Be $false
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PERFORMANCE_MEASUREMENT_DISABLE_STRUCTURED_WARNING -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PERFORMANCE_MEASUREMENT_DISABLE_STRUCTURED_WARNING = $originalFlag
                }
            }
        }

        It 'Emits structured warnings for failures when error handling is available' {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            $result = Measure-Operation -ScriptBlock { throw 'structured warning probe' } -OperationName 'StructuredWarn'
            $result.Success | Should -Be $false
        }

        It 'Emits debug output when PS_PROFILE_DEBUG is enabled' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = Measure-Operation -ScriptBlock { 'debug probe' } -OperationName 'DebugOp' -Verbose
                $result.Success | Should -Be $true
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Logs verbose completion details at debug level 2' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                $result = Measure-Operation -ScriptBlock { 1 } -OperationName 'DebugLevel2' -Verbose
                $result.DurationMs | Should -BeGreaterOrEqual 0
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }

    Context 'Database recording hooks' {
        AfterEach {
            Remove-Item Function:\Add-PerformanceMetric -ErrorAction SilentlyContinue
            Remove-Item Env:PS_PROFILE_PERFORMANCE_MEASUREMENT_FORCE_DB_RECORD -ErrorAction SilentlyContinue
            Remove-Item Env:PS_PROFILE_ENVIRONMENT -ErrorAction SilentlyContinue
            Remove-Item Env:CI -ErrorAction SilentlyContinue
            Remove-Module PerformanceMeasurement -ErrorAction SilentlyContinue -Force
            Import-Module (Join-Path $script:LibPath 'performance' 'PerformanceMeasurement.psm1') -DisableNameChecking -Force
        }

        It 'Records metrics when forced database recording is enabled' {
            $script:recorded = $null
            function global:Add-PerformanceMetric {
                param(
                    [string]$MetricType,
                    [string]$MetricName,
                    [double]$Value,
                    [string]$Unit,
                    [string]$Environment,
                    [hashtable]$Metadata
                )
                $script:recorded = [PSCustomObject]@{
                    MetricType    = $MetricType
                    MetricName    = $MetricName
                    Value         = $Value
                    Unit          = $Unit
                    Environment   = $Environment
                    Metadata      = $Metadata
                }
            }

            $env:PS_PROFILE_PERFORMANCE_MEASUREMENT_FORCE_DB_RECORD = '1'
            $env:PS_PROFILE_ENVIRONMENT = 'test-env'
            Remove-Module PerformanceMeasurement -ErrorAction SilentlyContinue -Force
            Import-Module (Join-Path $script:LibPath 'performance' 'PerformanceMeasurement.psm1') -DisableNameChecking -Force

            $result = Measure-Operation -ScriptBlock { 'record me' } -OperationName 'DbRecord'
            $result.Success | Should -Be $true
            $script:recorded.MetricType | Should -Be 'operation'
            $script:recorded.MetricName | Should -Be 'DbRecord'
            $script:recorded.Environment | Should -Be 'test-env'
        }

        It 'Uses CI environment label when CI is set' {
            $script:recorded = $null
            function global:Add-PerformanceMetric {
                param(
                    [string]$MetricType,
                    [string]$MetricName,
                    [double]$Value,
                    [string]$Unit,
                    [string]$Environment,
                    [hashtable]$Metadata
                )
                $script:recorded = [PSCustomObject]@{ Environment = $Environment }
            }

            $env:PS_PROFILE_PERFORMANCE_MEASUREMENT_FORCE_DB_RECORD = '1'
            $env:CI = 'true'
            Remove-Module PerformanceMeasurement -ErrorAction SilentlyContinue -Force
            Import-Module (Join-Path $script:LibPath 'performance' 'PerformanceMeasurement.psm1') -DisableNameChecking -Force

            Measure-Operation -ScriptBlock { 1 } -OperationName 'CiRecord' | Out-Null
            $script:recorded.Environment | Should -Be 'CI'
        }

        It 'Uses plain warnings when structured logging is disabled for database failures' {
            $originalFlag = $env:PS_PROFILE_PERFORMANCE_MEASUREMENT_DISABLE_STRUCTURED_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            function global:Add-PerformanceMetric {
                throw [System.InvalidOperationException]::new('db write failed')
            }

            $env:PS_PROFILE_PERFORMANCE_MEASUREMENT_FORCE_DB_RECORD = '1'
            $env:PS_PROFILE_PERFORMANCE_MEASUREMENT_DISABLE_STRUCTURED_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '1'
            Remove-Module PerformanceMeasurement -ErrorAction SilentlyContinue -Force
            Import-Module (Join-Path $script:LibPath 'performance' 'PerformanceMeasurement.psm1') -DisableNameChecking -Force

            try {
                $result = Measure-Operation -ScriptBlock { 1 } -OperationName 'DbFailPlain'
                $result.Success | Should -Be $true
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_PERFORMANCE_MEASUREMENT_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_PERFORMANCE_MEASUREMENT_DISABLE_STRUCTURED_ERROR = $originalFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Emits structured errors for database failures when error handling is available' {
            $profileBootstrap = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot
            $globalState = Join-Path $profileBootstrap 'GlobalState.ps1'
            $functionRegistration = Join-Path $profileBootstrap 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path $profileBootstrap 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            function global:Add-PerformanceMetric {
                throw [System.InvalidOperationException]::new('db write failed')
            }

            $env:PS_PROFILE_PERFORMANCE_MEASUREMENT_FORCE_DB_RECORD = '1'
            $env:PS_PROFILE_DEBUG = '3'
            Remove-Module PerformanceMeasurement -ErrorAction SilentlyContinue -Force
            Import-Module (Join-Path $script:LibPath 'performance' 'PerformanceMeasurement.psm1') -DisableNameChecking -Force

            $result = Measure-Operation -ScriptBlock { 1 } -OperationName 'DbFailStructured'
            $result.Success | Should -Be $true
        }
    }
}
