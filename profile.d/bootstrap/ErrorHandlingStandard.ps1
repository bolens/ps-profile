# ===============================================
# ErrorHandlingStandard.ps1
# Standardized error handling with OpenTelemetry conventions and wide events
# ===============================================

<#
.SYNOPSIS
    Standardized error handling following OpenTelemetry semantic conventions and wide events philosophy.

.DESCRIPTION
    Provides comprehensive error handling that:
    - Follows OpenTelemetry semantic conventions for error recording
    - Implements wide events approach (structured, contextual logging)
    - Supports tail sampling concepts (always keep errors, sample success)
    - Ensures consistent error recording across all modules
    - Captures business context along with technical errors

.NOTES
    Based on:
    - OpenTelemetry Error Handling Specification: https://opentelemetry.io/docs/specs/otel/error-handling/
    - Wide Events Philosophy: https://loggingsucks.com/
    
    Key Principles:
    1. One comprehensive event per operation with all context
    2. Structured logging with high-cardinality data
    3. Always record errors, sample successful operations
    4. Include business context, not just technical metrics
    5. Use semantic conventions for consistent attribute naming
#>

try {
    # Idempotency check
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'error-handling-standard') { return }
    }

    # Initialize event collection for wide events
    if (-not $global:WideEvents) {
        $global:WideEvents = [System.Collections.Generic.List[hashtable]]::new()
    }

    # Initialize error tracking for tail sampling
    if (-not $global:ErrorEventTracking) {
        $global:ErrorEventTracking = @{
            ErrorCount          = 0
            SlowRequestCount    = 0
            SampledSuccessCount = 0
            TotalEvents         = 0
        }
    }

    # ===============================================
    # Write-WideEvent - Emit structured wide events
    # ===============================================

    <#
    .SYNOPSIS
        Emits a structured wide event with comprehensive context.
    
    .DESCRIPTION
        Creates a wide event following OpenTelemetry semantic conventions.
        Wide events contain all context for an operation in a single structured event.
        Supports tail sampling: always keep errors, sample successful operations.
    
    .PARAMETER EventName
        Name of the event/operation (e.g., "database.query", "aws.s3.upload").
        Should follow OpenTelemetry naming conventions.
    
    .PARAMETER Level
        Log level: DEBUG, INFO, WARN, ERROR, FATAL.
        Maps to OpenTelemetry severity levels.
    
    .PARAMETER Context
        Hashtable of contextual data to include in the event.
        Should include business context (user_id, request_id) and technical context.
    
    .PARAMETER ErrorRecord
        Optional ErrorRecord to include error details.
        When provided, event is always kept (not sampled).
    
    .PARAMETER DurationMs
        Operation duration in milliseconds.
        Slow operations (> p99 threshold) are always kept.
    
    .PARAMETER AlwaysKeep
        Force keeping this event regardless of sampling rules.
        Use for VIP users, feature flags, or critical operations.
    
    .PARAMETER SampleRate
        Sampling rate for successful operations (0.0 to 1.0).
        Default: 0.05 (5%).
    
    .EXAMPLE
        Write-WideEvent -EventName "aws.s3.upload" -Level INFO -Context @{
            user_id = "user_123"
            bucket = "my-bucket"
            key = "file.txt"
            size_bytes = 1024
            region = "us-east-1"
        } -DurationMs 250
        
        Emits a structured event for S3 upload operation.
    
    .EXAMPLE
        Write-WideEvent -EventName "database.query" -Level ERROR -Context @{
            query = "SELECT * FROM users"
            database = "production"
        } -ErrorRecord $error -DurationMs 500
        
        Emits an error event (always kept, not sampled).
    
    .OUTPUTS
        System.Boolean. True if event was kept, false if sampled out.
    #>
    function Write-WideEvent {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$EventName,
            
            [Parameter(Mandatory = $true)]
            [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')]
            [string]$Level,
            
            [hashtable]$Context = @{},
            
            [System.Management.Automation.ErrorRecord]$ErrorRecord,
            
            [int]$DurationMs = 0,
            
            [switch]$AlwaysKeep,
            
            [double]$SampleRate = 0.05
        )

        # Build wide event following OpenTelemetry semantic conventions
        $event = @{
            # OpenTelemetry standard fields
            timestamp              = (Get-Date -Format 'o')  # ISO 8601
            event_name             = $EventName
            severity               = $Level
            severity_number        = switch ($Level) {
                'DEBUG' { 5 }
                'INFO' { 9 }
                'WARN' { 13 }
                'ERROR' { 17 }
                'FATAL' { 21 }
                default { 9 }
            }
            
            # Service identification (OpenTelemetry)
            service_name           = if ($env:PS_PROFILE_SERVICE_NAME) { $env:PS_PROFILE_SERVICE_NAME } else { 'powershell-profile' }
            service_version        = if ($env:PS_PROFILE_VERSION) { $env:PS_PROFILE_VERSION } else { 'unknown' }
            deployment_environment = if ($env:PS_PROFILE_ENV) { $env:PS_PROFILE_ENV } else { 'development' }
            
            # Operation context
            duration_ms            = $DurationMs
            outcome                = if ($ErrorRecord) { 'error' } elseif ($DurationMs -gt 0) { 'success' } else { 'unknown' }
            
            # Add all context (wide event philosophy: include everything)
            context                = $Context
        }

        # Add error details if ErrorRecord provided (OpenTelemetry exception recording)
        if ($ErrorRecord) {
            $event.error = @{
                type        = $ErrorRecord.Exception.GetType().FullName
                message     = $ErrorRecord.Exception.Message
                code        = if ($ErrorRecord.Exception.HResult) { $ErrorRecord.Exception.HResult } else { $null }
                stack_trace = $ErrorRecord.ScriptStackTrace
                source      = $ErrorRecord.InvocationInfo.ScriptName
                line_number = $ErrorRecord.InvocationInfo.ScriptLineNumber
            }
            
            # OpenTelemetry: Set status to error
            $event.status_code = 'ERROR'
            $event.status_message = $ErrorRecord.Exception.Message
        }
        else {
            $event.status_code = 'OK'
        }

        # Add invocation context (PowerShell-specific)
        $event.invocation = @{
            script_name   = $MyInvocation.ScriptName
            function_name = $MyInvocation.MyCommand.Name
            line_number   = $MyInvocation.ScriptLineNumber
            ps_version    = $PSVersionTable.PSVersion.ToString()
            host_name     = $Host.Name
        }

        # Tail sampling decision (from loggingsucks.com)
        $shouldKeep = $false
        
        if ($AlwaysKeep) {
            $shouldKeep = $true
        }
        elseif ($ErrorRecord) {
            # Always keep errors (100% retention)
            $shouldKeep = $true
            $global:ErrorEventTracking.ErrorCount++
        }
        elseif ($DurationMs -gt 0) {
            # Check if slow request (above p99 threshold)
            # Default threshold: 2000ms (configurable via env var)
            $slowThreshold = if ($env:PS_PROFILE_SLOW_THRESHOLD_MS) { 
                [int]$env:PS_PROFILE_SLOW_THRESHOLD_MS 
            }
            else { 
                2000 
            }
            
            if ($DurationMs -gt $slowThreshold) {
                $shouldKeep = $true
                $global:ErrorEventTracking.SlowRequestCount++
            }
            elseif ($Context.user_id -or $Context.user_id) {
                # Check for VIP users (configurable via env var)
                $vipUsers = if ($env:PS_PROFILE_VIP_USERS) {
                    $env:PS_PROFILE_VIP_USERS -split ','
                }
                else {
                    @()
                }
                
                if ($Context.user_id -in $vipUsers) {
                    $shouldKeep = $true
                }
            }
            
            # Random sample successful operations
            if (-not $shouldKeep) {
                $shouldKeep = (Get-Random -Minimum 0.0 -Maximum 1.0) -lt $SampleRate
                if ($shouldKeep) {
                    $global:ErrorEventTracking.SampledSuccessCount++
                }
            }
        }
        else {
            # No duration info: keep by default (might be important)
            $shouldKeep = $true
        }

        # Track total events
        $global:ErrorEventTracking.TotalEvents++

        # Emit event (always log, but mark if sampled)
        if ($shouldKeep) {
            $event.sampled = $false
            $event.retention_reason = if ($ErrorRecord) { 'error' }
            elseif ($DurationMs -gt 2000) { 'slow' }
            elseif ($AlwaysKeep) { 'explicit' }
            else { 'sampled' }
            
            # Add to collection for batch processing
            $global:WideEvents.Add($event)
            
            # Emit to console/log based on level
            $emitToConsole = if ($env:PS_PROFILE_SUPPRESS_EVENTS) { $false } else { $true }
            
            if ($emitToConsole) {
                # Format for console output
                $eventJson = $event | ConvertTo-Json -Depth 10 -Compress
                
                switch ($Level) {
                    'ERROR' { Write-Error $eventJson -ErrorAction SilentlyContinue }
                    'FATAL' { Write-Error $eventJson -ErrorAction SilentlyContinue }
                    'WARN' { Write-Warning $eventJson }
                    'INFO' { Write-Host $eventJson -ForegroundColor Cyan }
                    'DEBUG' { Write-Verbose $eventJson }
                }
            }
            
            return $true
        }
        else {
            # Event sampled out (not kept)
            $event.sampled = $true
            $event.retention_reason = 'sampled_out'
            return $false
        }
    }

    # ===============================================
    # Write-StructuredError - Standardized error recording
    # ===============================================

    <#
    .SYNOPSIS
        Records an error following OpenTelemetry semantic conventions.
    
    .DESCRIPTION
        Records exceptions and errors with full context, following OpenTelemetry standards.
        Always keeps error events (not subject to sampling).
    
    .PARAMETER ErrorRecord
        The ErrorRecord to record.
    
    .PARAMETER Context
        Additional context about the error (operation name, user, etc.).
    
    .PARAMETER OperationName
        Name of the operation that failed (OpenTelemetry span name).
    
    .PARAMETER StatusCode
        HTTP or operation status code (if applicable).
    
    .PARAMETER Retriable
        Whether the error is retriable.
    
    .EXAMPLE
        try {
            $result = Invoke-Aws s3 ls
        }
        catch {
            Write-StructuredError -ErrorRecord $_ -OperationName "aws.s3.list" -Context @{
                bucket = "my-bucket"
                region = "us-east-1"
            }
        }
    
    .OUTPUTS
        None. Error is recorded and event is emitted.
    #>
    function Write-StructuredError {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [System.Management.Automation.ErrorRecord]$ErrorRecord,
            
            [hashtable]$Context = @{},
            
            [string]$OperationName = 'unknown',
            
            [int]$StatusCode = 0,
            
            [switch]$Retriable
        )

        # Build error context
        $errorContext = $Context.Clone()
        $errorContext.operation_name = $OperationName
        $errorContext.status_code = $StatusCode
        $errorContext.retriable = $Retriable.IsPresent

        # Emit as wide event (errors are always kept)
        Write-WideEvent -EventName $OperationName -Level ERROR -Context $errorContext -ErrorRecord $ErrorRecord -AlwaysKeep
    }

    # ===============================================
    # Write-StructuredWarning - Standardized warning recording
    # ===============================================

    <#
    .SYNOPSIS
        Records a warning with structured context.
    
    .DESCRIPTION
        Records warnings following OpenTelemetry conventions.
        Warnings may be sampled based on configuration.
    
    .PARAMETER Message
        Warning message.
    
    .PARAMETER Context
        Additional context about the warning.
    
    .PARAMETER OperationName
        Name of the operation (OpenTelemetry span name).
    
    .PARAMETER Code
        Warning code for categorization.
    
    .EXAMPLE
        Write-StructuredWarning -Message "Slow query detected" -OperationName "database.query" -Context @{
            query = "SELECT * FROM users"
            duration_ms = 2500
        }
    
    .OUTPUTS
        None. Warning is recorded.
    #>
    function Write-StructuredWarning {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message,
            
            [hashtable]$Context = @{},
            
            [string]$OperationName = 'unknown',
            
            [string]$Code
        )

        $warningContext = $Context.Clone()
        $warningContext.message = $Message
        $warningContext.warning_code = $Code

        Write-WideEvent -EventName $OperationName -Level WARN -Context $warningContext
    }

    # ===============================================
    # Invoke-WithWideEvent - Wrap operations with wide event tracking
    # ===============================================

    <#
    .SYNOPSIS
        Wraps an operation with wide event tracking.
    
    .DESCRIPTION
        Executes a script block and automatically creates a wide event with timing,
        success/failure, and error details. Follows the wide events pattern of
        building context throughout the operation lifecycle.
    
    .PARAMETER OperationName
        Name of the operation (OpenTelemetry span name).
    
    .PARAMETER ScriptBlock
        Script block to execute.
    
    .PARAMETER Context
        Initial context to include in the event.
    
    .PARAMETER Level
        Log level for successful operations.
    
    .PARAMETER AlwaysKeep
        Force keeping this event regardless of sampling.
    
    .EXAMPLE
        Invoke-WithWideEvent -OperationName "aws.s3.upload" -Context @{
            bucket = "my-bucket"
            key = "file.txt"
        } -ScriptBlock {
            aws s3 cp file.txt s3://my-bucket/file.txt
        }
    
    .OUTPUTS
        System.Object. Result from ScriptBlock execution.
    #>
    function Invoke-WithWideEvent {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$OperationName,
            
            [Parameter(Mandatory = $true)]
            [scriptblock]$ScriptBlock,
            
            [hashtable]$Context = @{},
            
            [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')]
            [string]$Level = 'INFO',
            
            [switch]$AlwaysKeep
        )

        $startTime = Get-Date
        $eventContext = $Context.Clone()
        $errorRecord = $null
        $success = $false

        try {
            # Execute the operation
            $result = & $ScriptBlock
            $success = $true
            $eventContext.outcome = 'success'
            return $result
        }
        catch {
            $errorRecord = $_
            $eventContext.outcome = 'error'
            $eventContext.error_occurred = $true
            throw
        }
        finally {
            $duration = ((Get-Date) - $startTime).TotalMilliseconds
            $eventContext.duration_ms = [math]::Round($duration, 2)

            # Emit wide event
            $eventLevel = if ($errorRecord) { 'ERROR' } else { $Level }
            Write-WideEvent -EventName $OperationName -Level $eventLevel -Context $eventContext -ErrorRecord $errorRecord -DurationMs $eventContext.duration_ms -AlwaysKeep:$AlwaysKeep
        }
    }

    # ===============================================
    # EventSamplingStats Class - Type-safe statistics
    # ===============================================

    class EventSamplingStats {
        [int]$TotalEvents
        [int]$ErrorCount
        [int]$SlowRequestCount
        [int]$SampledSuccessCount
        [int]$KeptEvents
        [double]$ErrorRetentionRate
        [double]$SuccessSamplingRate

        EventSamplingStats() {
            $this.TotalEvents = 0
            $this.ErrorCount = 0
            $this.SlowRequestCount = 0
            $this.SampledSuccessCount = 0
            $this.KeptEvents = 0
            $this.ErrorRetentionRate = 0.0
            $this.SuccessSamplingRate = 0.0
        }

        [double]GetErrorRate() {
            if ($this.TotalEvents -eq 0) { return 0.0 }
            return $this.ErrorCount / $this.TotalEvents
        }

        [double]GetSlowRequestRate() {
            if ($this.TotalEvents -eq 0) { return 0.0 }
            return $this.SlowRequestCount / $this.TotalEvents
        }

        [string]ToString() {
            return "Events: $($this.TotalEvents), Errors: $($this.ErrorCount), Slow: $($this.SlowRequestCount), Kept: $($this.KeptEvents)"
        }
    }

    # ===============================================
    # Get-EventSamplingStats - Get sampling statistics
    # ===============================================

    <#
    .SYNOPSIS
        Gets statistics about event sampling.
    
    .DESCRIPTION
        Returns statistics about how events are being sampled,
        useful for monitoring and adjusting sampling rates.
    
    .EXAMPLE
        Get-EventSamplingStats
        
        Returns sampling statistics.
    
    .OUTPUTS
        EventSamplingStats. Sampling statistics with type-safe properties and helper methods.
    #>
    function Get-EventSamplingStats {
        [CmdletBinding()]
        [OutputType([EventSamplingStats])]
        param()

        $stats = [EventSamplingStats]@{
            TotalEvents         = $global:ErrorEventTracking.TotalEvents
            ErrorCount          = $global:ErrorEventTracking.ErrorCount
            SlowRequestCount    = $global:ErrorEventTracking.SlowRequestCount
            SampledSuccessCount = $global:ErrorEventTracking.SampledSuccessCount
            KeptEvents          = $global:WideEvents.Count
            ErrorRetentionRate  = if ($global:ErrorEventTracking.ErrorCount -gt 0) { 1.0 } else { 0.0 }
            SuccessSamplingRate = if ($global:ErrorEventTracking.TotalEvents -gt 0) {
                $global:ErrorEventTracking.SampledSuccessCount / ($global:ErrorEventTracking.TotalEvents - $global:ErrorEventTracking.ErrorCount)
            }
            else { 0.0 }
        }

        return $stats
    }

    # ===============================================
    # Clear-EventCollection - Clear collected events
    # ===============================================

    <#
    .SYNOPSIS
        Clears the collected wide events.
    
    .DESCRIPTION
        Clears the in-memory event collection.
        Useful for testing or periodic cleanup.
    
    .EXAMPLE
        Clear-EventCollection
        
        Clears all collected events.
    
    .OUTPUTS
        System.Int32. Number of events cleared.
    #>
    function Clear-EventCollection {
        [CmdletBinding()]
        [OutputType([int])]
        param()

        $count = $global:WideEvents.Count
        $global:WideEvents.Clear()
        return $count
    }

    # Register functions
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Write-WideEvent' -Body ${function:Write-WideEvent}
        Set-AgentModeFunction -Name 'Write-StructuredError' -Body ${function:Write-StructuredError}
        Set-AgentModeFunction -Name 'Write-StructuredWarning' -Body ${function:Write-StructuredWarning}
        Set-AgentModeFunction -Name 'Invoke-WithWideEvent' -Body ${function:Invoke-WithWideEvent}
        Set-AgentModeFunction -Name 'Get-EventSamplingStats' -Body ${function:Get-EventSamplingStats}
        Set-AgentModeFunction -Name 'Clear-EventCollection' -Body ${function:Clear-EventCollection}
    }
    else {
        # Fallback: direct function registration
        Set-Item -Path Function:Write-WideEvent -Value ${function:Write-WideEvent} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Write-StructuredError -Value ${function:Write-StructuredError} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Write-StructuredWarning -Value ${function:Write-StructuredWarning} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Invoke-WithWideEvent -Value ${function:Invoke-WithWideEvent} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-EventSamplingStats -Value ${function:Get-EventSamplingStats} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Clear-EventCollection -Value ${function:Clear-EventCollection} -Force -ErrorAction SilentlyContinue
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'error-handling-standard'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: error-handling-standard" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load error-handling-standard fragment: $($_.Exception.Message)"
    }
}
