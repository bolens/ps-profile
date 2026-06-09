# Write-StructuredWarning

## Synopsis

Records a warning with structured context.

## Description

Records warnings following OpenTelemetry conventions. Warnings may be sampled based on configuration.

## Signature

```powershell
Write-StructuredWarning
```

## Parameters

### -Message

Warning message.

### -Context

Additional context about the warning.

### -OperationName

Name of the operation (OpenTelemetry span name).

### -Code

Warning code for categorization.


## Outputs

None. Warning is recorded.


## Examples

### Example 1

```powershell
Write-StructuredWarning -Message "Slow query detected" -OperationName "database.query" -Context @{
```

query = "SELECT * FROM users" duration_ms = 2500 }

## Source

Defined in: ../profile.d/bootstrap/ErrorHandlingStandard.ps1
