# Write-StructuredError

## Synopsis

Records an error following OpenTelemetry semantic conventions.

## Description

Records exceptions and errors with full context, following OpenTelemetry standards. Always keeps error events (not subject to sampling).

## Signature

```powershell
Write-StructuredError
```

## Parameters

### -ErrorRecord

The ErrorRecord to record.

### -Context

Additional context about the error (operation name, user, etc.).

### -OperationName

Name of the operation that failed (OpenTelemetry span name).

### -StatusCode

HTTP or operation status code (if applicable).

### -Retriable

Whether the error is retriable.


## Outputs

None. Error is recorded and event is emitted.


## Examples

### Example 1

```powershell
try {
```

$result = Invoke-Aws s3 ls } catch { Write-StructuredError -ErrorRecord $_ -OperationName "aws.s3.list" -Context @{ bucket = "my-bucket" region = "us-east-1" } }

## Source

Defined in: ../profile.d/bootstrap/ErrorHandlingStandard.ps1
