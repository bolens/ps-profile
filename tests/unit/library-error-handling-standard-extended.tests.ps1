<#
tests/unit/library-error-handling-standard-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ErrorHandlingStandard sampling and severity edge cases.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')

    $errorHandlingPath = Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1'
    if (Test-Path -LiteralPath $errorHandlingPath) {
        . $errorHandlingPath
    }

    if ($global:ErrorEventTracking) {
        $global:ErrorEventTracking.ErrorCount = 0
        $global:ErrorEventTracking.SlowRequestCount = 0
        $global:ErrorEventTracking.SampledSuccessCount = 0
        $global:ErrorEventTracking.TotalEvents = 0
    }
}

Describe 'ErrorHandlingStandard extended scenarios' {
    BeforeEach {
        if (Get-Command Clear-EventCollection -ErrorAction SilentlyContinue) {
            Clear-EventCollection | Out-Null
        }

        if ($global:ErrorEventTracking) {
            $global:ErrorEventTracking.ErrorCount = 0
            $global:ErrorEventTracking.SlowRequestCount = 0
            $global:ErrorEventTracking.SampledSuccessCount = 0
            $global:ErrorEventTracking.TotalEvents = 0
        }
    }

    Context 'Write-WideEvent severity handling' {
        It 'Maps FATAL events to the highest severity number' {
            Write-WideEvent -EventName 'test.fatal' -Level FATAL -Context @{} -AlwaysKeep

            $global:WideEvents[-1].severity | Should -Be 'FATAL'
            $global:WideEvents[-1].severity_number | Should -Be 21
        }

        It 'Marks error events with ERROR status_code' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.InvalidOperationException]::new('extended-error'),
                'ExtendedError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )

            Write-WideEvent -EventName 'test.error.status' -Level ERROR -ErrorRecord $errorRecord -Context @{} -AlwaysKeep

            $global:WideEvents[-1].status_code | Should -Be 'ERROR'
        }
    }

    Context 'Tail sampling edge cases' {
        It 'Does not keep fast successful events when sample rate is zero' {
            $beforeCount = @($global:WideEvents).Count

            $kept = Write-WideEvent -EventName 'test.zero-sample' -Level INFO -Context @{} -DurationMs 50 -SampleRate 0

            $kept | Should -Be $false
            @($global:WideEvents).Count | Should -Be $beforeCount
        }

        It 'Always keeps slow requests even without AlwaysKeep' {
            $env:PS_PROFILE_SLOW_THRESHOLD_MS = '100'

            try {
                $kept = Write-WideEvent -EventName 'test.slow.extended' -Level INFO -Context @{} -DurationMs 500

                $kept | Should -Be $true
                $global:WideEvents[-1].event_name | Should -Be 'test.slow.extended'
            }
            finally {
                Remove-Item Env:\PS_PROFILE_SLOW_THRESHOLD_MS -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Invoke-WithWideEvent extended behavior' {
        It 'Records WARN level events from script blocks' {
            Invoke-WithWideEvent -OperationName 'test.warn.block' -Level WARN -Context @{ reason = 'extended' } -AlwaysKeep -ScriptBlock {
                'warn-result'
            } | Should -Be 'warn-result'

            $global:WideEvents[-1].severity | Should -Be 'WARN'
            $global:WideEvents[-1].context.reason | Should -Be 'extended'
        }

        It 'Includes duration metadata for timed operations' {
            Invoke-WithWideEvent -OperationName 'test.duration.extended' -Context @{} -AlwaysKeep -ScriptBlock {
                Start-Sleep -Milliseconds 15
                'timed'
            } | Should -Be 'timed'

            $global:WideEvents[-1].duration_ms | Should -BeGreaterThan 0
        }
    }
}
