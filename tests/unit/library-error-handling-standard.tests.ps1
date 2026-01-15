# ===============================================
# library-error-handling-standard.tests.ps1
# Unit tests for ErrorHandlingStandard.ps1
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    
    # Load bootstrap first
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    
    # Load ErrorHandlingStandard module
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
    
    # Clear event collections before tests
    if (Get-Command Clear-EventCollection -ErrorAction SilentlyContinue) {
        Clear-EventCollection | Out-Null
    }
    
    # Reset tracking
    if ($global:ErrorEventTracking) {
        $global:ErrorEventTracking.ErrorCount = 0
        $global:ErrorEventTracking.SlowRequestCount = 0
        $global:ErrorEventTracking.SampledSuccessCount = 0
        $global:ErrorEventTracking.TotalEvents = 0
    }
}

AfterEach {
    # Clear events after each test
    if (Get-Command Clear-EventCollection -ErrorAction SilentlyContinue) {
        Clear-EventCollection | Out-Null
    }
}

Describe 'ErrorHandlingStandard.ps1 - Write-WideEvent' {
    Context 'Basic Event Creation' {
        It 'Creates a wide event with required parameters' {
            $result = Write-WideEvent -EventName 'test.operation' -Level INFO -Context @{ test = 'value' }
            
            $result | Should -BeOfType [bool]
            $global:WideEvents.Count | Should -BeGreaterThan 0
            
            $event = $global:WideEvents[-1]
            $event.event_name | Should -Be 'test.operation'
            $event.severity | Should -Be 'INFO'
            $event.context.test | Should -Be 'value'
        }
        
        It 'Includes OpenTelemetry standard fields' {
            Write-WideEvent -EventName 'test.otel' -Level INFO -Context @{}
            
            $event = $global:WideEvents[-1]
            $event.PSObject.Properties['timestamp'] | Should -Not -BeNullOrEmpty
            $event.PSObject.Properties['service_name'] | Should -Not -BeNullOrEmpty
            $event.PSObject.Properties['severity_number'] | Should -Not -BeNullOrEmpty
            $event.PSObject.Properties['status_code'] | Should -Not -BeNullOrEmpty
        }
        
        It 'Maps severity levels to numbers correctly' {
            $levels = @{
                'DEBUG' = 5
                'INFO'  = 9
                'WARN'  = 13
                'ERROR' = 17
                'FATAL' = 21
            }
            
            foreach ($level in $levels.Keys) {
                Write-WideEvent -EventName "test.$level" -Level $level -Context @{}
                $event = $global:WideEvents[-1]
                $event.severity_number | Should -Be $levels[$level]
            }
        }
    }
    
    Context 'Error Recording' {
        It 'Always keeps error events' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Test error'),
                'TestError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            
            $result = Write-WideEvent -EventName 'test.error' -Level ERROR -ErrorRecord $errorRecord -Context @{}
            
            $result | Should -Be $true
            $event = $global:WideEvents[-1]
            $event.error | Should -Not -BeNullOrEmpty
            $event.error.type | Should -Not -BeNullOrEmpty
            $event.error.message | Should -Be 'Test error'
            $event.status_code | Should -Be 'ERROR'
            $event.retention_reason | Should -Be 'error'
        }
        
        It 'Increments error count in tracking' {
            $initialCount = $global:ErrorEventTracking.ErrorCount
            
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Test'),
                'Test',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            
            Write-WideEvent -EventName 'test.error' -Level ERROR -ErrorRecord $errorRecord -Context @{}
            
            $global:ErrorEventTracking.ErrorCount | Should -Be ($initialCount + 1)
        }
    }
    
    Context 'Tail Sampling' {
        It 'Keeps slow requests above threshold' {
            $env:PS_PROFILE_SLOW_THRESHOLD_MS = '100'
            
            $result = Write-WideEvent -EventName 'test.slow' -Level INFO -Context @{} -DurationMs 250
            
            $result | Should -Be $true
            $event = $global:WideEvents[-1]
            $event.retention_reason | Should -Be 'slow'
            
            Remove-Item Env:PS_PROFILE_SLOW_THRESHOLD_MS -ErrorAction SilentlyContinue
        }
        
        It 'Samples successful operations by default' {
            # Run multiple events to test sampling
            $keptCount = 0
            for ($i = 0; $i -lt 20; $i++) {
                $result = Write-WideEvent -EventName "test.sample.$i" -Level INFO -Context @{} -DurationMs 100 -SampleRate 0.5
                if ($result) { $keptCount++ }
            }
            
            # With 50% sample rate, we should get some but not all
            $keptCount | Should -BeGreaterThan 0
            $keptCount | Should -BeLessThan 20
        }
        
        It 'Always keeps events with AlwaysKeep flag' {
            $result = Write-WideEvent -EventName 'test.keep' -Level INFO -Context @{} -AlwaysKeep
            
            $result | Should -Be $true
            $event = $global:WideEvents[-1]
            $event.retention_reason | Should -Be 'explicit'
        }
    }
    
    Context 'Context and Metadata' {
        It 'Includes invocation context' {
            Write-WideEvent -EventName 'test.invocation' -Level INFO -Context @{}
            
            $event = $global:WideEvents[-1]
            $event.invocation | Should -Not -BeNullOrEmpty
            $event.invocation.function_name | Should -Be 'Write-WideEvent'
            $event.invocation.ps_version | Should -Not -BeNullOrEmpty
        }
        
        It 'Includes all context data' {
            $context = @{
                user_id      = 'user123'
                request_id   = 'req456'
                custom_field = 'custom_value'
            }
            
            Write-WideEvent -EventName 'test.context' -Level INFO -Context $context
            
            $event = $global:WideEvents[-1]
            $event.context.user_id | Should -Be 'user123'
            $event.context.request_id | Should -Be 'req456'
            $event.context.custom_field | Should -Be 'custom_value'
        }
    }
}

Describe 'ErrorHandlingStandard.ps1 - Write-StructuredError' {
    Context 'Error Recording' {
        It 'Records error with operation name' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Test error'),
                'TestError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            
            Write-StructuredError -ErrorRecord $errorRecord -OperationName 'test.operation' -Context @{ test = 'value' }
            
            $event = $global:WideEvents[-1]
            $event.event_name | Should -Be 'test.operation'
            $event.severity | Should -Be 'ERROR'
            $event.context.operation_name | Should -Be 'test.operation'
            $event.context.test | Should -Be 'value'
        }
        
        It 'Includes status code and retriable flag' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Test'),
                'Test',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            
            Write-StructuredError -ErrorRecord $errorRecord -OperationName 'test' -StatusCode 500 -Retriable
            
            $event = $global:WideEvents[-1]
            $event.context.status_code | Should -Be 500
            $event.context.retriable | Should -Be $true
        }
    }
}

Describe 'ErrorHandlingStandard.ps1 - Write-StructuredWarning' {
    Context 'Warning Recording' {
        It 'Records warning with message' {
            Write-StructuredWarning -Message 'Test warning' -OperationName 'test.warning' -Context @{}
            
            $event = $global:WideEvents[-1]
            $event.event_name | Should -Be 'test.warning'
            $event.severity | Should -Be 'WARN'
            $event.context.message | Should -Be 'Test warning'
        }
        
        It 'Includes warning code' {
            Write-StructuredWarning -Message 'Warning' -OperationName 'test' -Code 'WARN001' -Context @{}
            
            $event = $global:WideEvents[-1]
            $event.context.warning_code | Should -Be 'WARN001'
        }
    }
}

Describe 'ErrorHandlingStandard.ps1 - Invoke-WithWideEvent' {
    Context 'Successful Operations' {
        It 'Executes script block and records success' {
            $result = Invoke-WithWideEvent -OperationName 'test.success' -Context @{ test = 'value' } -ScriptBlock {
                return 'success'
            }
            
            $result | Should -Be 'success'
            $event = $global:WideEvents[-1]
            $event.event_name | Should -Be 'test.success'
            $event.context.outcome | Should -Be 'success'
            $event.context.duration_ms | Should -BeGreaterThan 0
        }
        
        It 'Includes context in event' {
            $context = @{ user_id = 'user123' }
            
            Invoke-WithWideEvent -OperationName 'test.context' -Context $context -ScriptBlock {
                return 'ok'
            }
            
            $event = $global:WideEvents[-1]
            $event.context.user_id | Should -Be 'user123'
        }
    }
    
    Context 'Error Handling' {
        It 'Records error when script block throws' {
            $errorThrown = $false
            try {
                Invoke-WithWideEvent -OperationName 'test.error' -Context @{} -ScriptBlock {
                    throw 'Test error'
                }
            }
            catch {
                $errorThrown = $true
            }
            
            $errorThrown | Should -Be $true
            $event = $global:WideEvents[-1]
            $event.event_name | Should -Be 'test.error'
            $event.severity | Should -Be 'ERROR'
            $event.context.outcome | Should -Be 'error'
            $event.error | Should -Not -BeNullOrEmpty
        }
        
        It 'Re-throws exception after recording' {
            {
                Invoke-WithWideEvent -OperationName 'test.rethrow' -Context @{} -ScriptBlock {
                    throw 'Test'
                }
            } | Should -Throw
        }
    }
    
    Context 'Timing' {
        It 'Records operation duration' {
            Invoke-WithWideEvent -OperationName 'test.timing' -Context @{} -ScriptBlock {
                Start-Sleep -Milliseconds 50
            }
            
            $event = $global:WideEvents[-1]
            $event.context.duration_ms | Should -BeGreaterThan 40
            $event.duration_ms | Should -BeGreaterThan 40
        }
    }
}

Describe 'ErrorHandlingStandard.ps1 - Get-EventSamplingStats' {
    Context 'Statistics Collection' {
        It 'Returns sampling statistics' {
            # Generate some events
            Write-WideEvent -EventName 'test.1' -Level INFO -Context @{} -DurationMs 100
            Write-WideEvent -EventName 'test.2' -Level INFO -Context @{} -DurationMs 100
            
            $stats = Get-EventSamplingStats
            
            $stats.PSObject.Properties['TotalEvents'] | Should -Not -BeNullOrEmpty
            $stats.PSObject.Properties['ErrorCount'] | Should -Not -BeNullOrEmpty
            $stats.PSObject.Properties['KeptEvents'] | Should -Not -BeNullOrEmpty
        }
        
        It 'Tracks error retention rate' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Test'),
                'Test',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            
            Write-WideEvent -EventName 'test.error' -Level ERROR -ErrorRecord $errorRecord -Context @{}
            
            $stats = Get-EventSamplingStats
            if ($stats.ErrorCount -gt 0) {
                $stats.ErrorRetentionRate | Should -Be 1.0
            }
        }
    }
}

Describe 'ErrorHandlingStandard.ps1 - Clear-EventCollection' {
    Context 'Event Cleanup' {
        It 'Clears all collected events' {
            # Add some events
            Write-WideEvent -EventName 'test.1' -Level INFO -Context @{}
            Write-WideEvent -EventName 'test.2' -Level INFO -Context @{}
            
            $beforeCount = $global:WideEvents.Count
            $beforeCount | Should -BeGreaterThan 0
            
            $clearedCount = Clear-EventCollection
            
            $clearedCount | Should -Be $beforeCount
            $global:WideEvents.Count | Should -Be 0
        }
        
        It 'Returns zero when collection is empty' {
            Clear-EventCollection | Out-Null
            
            $result = Clear-EventCollection
            $result | Should -Be 0
        }
    }
}
