# ===============================================
# standard.tests.ps1
# Integration tests for ErrorHandlingStandard.ps1
# ===============================================

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
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    
    # Load bootstrap
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    
    # Load ErrorHandlingStandard
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
}

Describe 'ErrorHandlingStandard.ps1 - Integration Tests' {
    AfterEach {
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

    Context 'Module Loading' {
        It 'Loads without errors' {
            { . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1') } | Should -Not -Throw
        }
        
        It 'Is idempotent (can be loaded multiple times)' {
            {
                . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
                . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
            } | Should -Not -Throw
        }
        
        It 'Registers all required functions' {
            Get-Command Write-WideEvent -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Write-StructuredError -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Get-EventSamplingStats -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Clear-EventCollection -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'OpenTelemetry Compliance' {
        It 'Follows OpenTelemetry semantic conventions' {
            Write-WideEvent -EventName 'otel.test' -Level INFO -Context @{ test = 'value' } -AlwaysKeep
            
            $global:WideEvents.Count | Should -BeGreaterThan 0
            $event = $global:WideEvents[$global:WideEvents.Count - 1]
            
            # Required OpenTelemetry fields (events are stored as hashtables)
            $event['timestamp'] | Should -Not -BeNullOrEmpty
            $event['severity'] | Should -Not -BeNullOrEmpty
            $event['severity_number'] | Should -Not -BeNullOrEmpty
            $event['service_name'] | Should -Not -BeNullOrEmpty
            $event['status_code'] | Should -Not -BeNullOrEmpty
        }
        
        It 'Records exceptions following OpenTelemetry format' {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('OTel test error'),
                'OTelTest',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            
            Write-WideEvent -EventName 'otel.error' -Level ERROR -ErrorRecord $errorRecord -Context @{}
            
            $global:WideEvents.Count | Should -BeGreaterThan 0
            $event = $global:WideEvents[$global:WideEvents.Count - 1]
            $event.error.type | Should -Not -BeNullOrEmpty
            $event.error.message | Should -Be 'OTel test error'
            $event.status_code | Should -Be 'ERROR'
            $event.status_message | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Wide Events Philosophy' {
        It 'Includes comprehensive context in single event' {
            $context = @{
                user_id          = 'user123'
                request_id       = 'req456'
                feature_flag     = 'new-feature'
                business_context = 'important-operation'
            }
            
            Write-WideEvent -EventName 'wide.test' -Level INFO -Context $context -DurationMs 150 -AlwaysKeep
            
            $global:WideEvents.Count | Should -BeGreaterThan 0
            $event = $global:WideEvents[$global:WideEvents.Count - 1]
            $event.context.user_id | Should -Be 'user123'
            $event.context.request_id | Should -Be 'req456'
            $event.context.feature_flag | Should -Be 'new-feature'
            $event.context.business_context | Should -Be 'important-operation'
            $event.duration_ms | Should -Be 150
        }
        
        It 'Captures both business and technical context' {
            $context = @{
                user_id           = 'user123'
                database          = 'production'
                query             = 'SELECT * FROM users'
                execution_time_ms = 250
            }
            
            Write-WideEvent -EventName 'wide.db.query' -Level INFO -Context $context -AlwaysKeep
            
            $global:WideEvents.Count | Should -BeGreaterThan 0
            $event = $global:WideEvents[$global:WideEvents.Count - 1]
            # Business context
            $event.context.user_id | Should -Be 'user123'
            # Technical context
            $event.context.database | Should -Be 'production'
            $event.context.query | Should -Be 'SELECT * FROM users'
        }
    }
    
    Context 'Tail Sampling' {
        It 'Always keeps errors (100% retention)' {
            $initialErrorCount = $global:ErrorEventTracking.ErrorCount
            
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Test'),
                'Test',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            
            for ($i = 0; $i -lt 10; $i++) {
                Write-WideEvent -EventName "test.error.$i" -Level ERROR -ErrorRecord $errorRecord -Context @{}
            }
            
            $global:ErrorEventTracking.ErrorCount | Should -Be ($initialErrorCount + 10)
        }
        
        It 'Keeps slow requests above threshold' {
            $env:PS_PROFILE_SLOW_THRESHOLD_MS = '100'
            
            $initialSlowCount = $global:ErrorEventTracking.SlowRequestCount
            
            Write-WideEvent -EventName 'test.slow' -Level INFO -Context @{} -DurationMs 250
            
            $global:ErrorEventTracking.SlowRequestCount | Should -Be ($initialSlowCount + 1)
            
            Remove-Item Env:PS_PROFILE_SLOW_THRESHOLD_MS -ErrorAction SilentlyContinue
        }
        
        It 'Samples successful operations' {
            $initialSampledCount = $global:ErrorEventTracking.SampledSuccessCount
            
            # Generate many successful events
            for ($i = 0; $i -lt 50; $i++) {
                Write-WideEvent -EventName "test.success.$i" -Level INFO -Context @{} -DurationMs 50 -SampleRate 0.1
            }
            
            # Some should be sampled
            $global:ErrorEventTracking.SampledSuccessCount | Should -BeGreaterThan $initialSampledCount
        }
    }
    
    Context 'Real-World Scenarios' {
        It 'Tracks database operation with full context' {
            Invoke-WithWideEvent -OperationName 'database.query' -Context @{
                user_id    = 'user123'
                database   = 'production'
                query      = 'SELECT * FROM users WHERE id = ?'
                parameters = @('user123')
            } -AlwaysKeep -ScriptBlock {
                Start-Sleep -Milliseconds 50
                return @{ count = 1 }
            }
            
            $global:WideEvents.Count | Should -BeGreaterThan 0
            $event = $global:WideEvents[$global:WideEvents.Count - 1]
            $event.event_name | Should -Be 'database.query'
            $event.context.user_id | Should -Be 'user123'
            $event.context.database | Should -Be 'production'
            $event.context.outcome | Should -Be 'success'
        }
        
        It 'Tracks cloud operation with error handling' {
            try {
            $errorThrown = $false
                        Invoke-WithWideEvent -OperationName 'aws.s3.upload' -Context @{
                bucket     = 'my-bucket'
                key        = 'file.txt'
                size_bytes = 1024
            } -ScriptBlock {
                throw 'S3 upload failed'
            }
            }
            catch {
                $errorThrown = $true
            
                $errorThrown | Should -Be $true
                $global:WideEvents.Count | Should -BeGreaterThan 0
                $event = $global:WideEvents[$global:WideEvents.Count - 1]
                $event.event_name | Should -Be 'aws.s3.upload'
                $event.context.bucket | Should -Be 'my-bucket'
                $event.severity | Should -Be 'ERROR'
            }
        }
    }
}
