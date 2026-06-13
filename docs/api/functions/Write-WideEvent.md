# Write-WideEvent

## Synopsis

Emits a structured wide event with comprehensive context.

## Description

Creates a wide event following OpenTelemetry semantic conventions. Wide events contain all context for an operation in a single structured event. Supports tail sampling: always keep errors, sample successful operations.

## Signature

```powershell
Write-WideEvent
```

## Parameters

### -EventName

Name of the event/operation (e.g., "database.query", "aws.s3.upload"). Should follow OpenTelemetry naming conventions.

### -Level

Log level: DEBUG, INFO, WARN, ERROR, FATAL. Maps to OpenTelemetry severity levels.

### -Context

Hashtable of contextual data to include in the event. Should include business context (user_id, request_id) and technical context.

### -ErrorRecord

Optional ErrorRecord to include error details. When provided, event is always kept (not sampled).

### -DurationMs

Operation duration in milliseconds. Slow operations (> p99 threshold) are always kept.

### -AlwaysKeep

Force keeping this event regardless of sampling rules. Use for VIP users, feature flags, or critical operations.

### -SampleRate

Sampling rate for successful operations (0.0 to 1.0). Default: 0.05 (5%).


## Outputs

System.Boolean. True if event was kept, false if sampled out.


## Examples

### Example 1

```powershell
Write-WideEvent -EventName "aws.s3.upload" -Level INFO -Context @{
```

user_id = "user_123" bucket = "my-bucket" key = "file.txt" size_bytes = 1024 region = "us-east-1" } -DurationMs 250 Emits a structured event for S3 upload operation.

### Example 2

```powershell
Write-WideEvent -EventName "database.query" -Level ERROR -Context @{
```

query = "SELECT * FROM users" database = "production" } -ErrorRecord $error -DurationMs 500 Emits an error event (always kept, not sampled).

## Source

Defined in: ../profile.d/bootstrap/ErrorHandlingStandard.ps1
