# GetErrorRate

## Synopsis

Wraps an operation with wide event tracking.

## Description

Executes a script block and automatically creates a wide event with timing, success/failure, and error details. Follows the wide events pattern of building context throughout the operation lifecycle.

## Signature

```powershell
GetErrorRate
```

## Parameters

### -OperationName

Name of the operation (OpenTelemetry span name).

### -ScriptBlock

Script block to execute.

### -Context

Initial context to include in the event.

### -Level

Log level for successful operations.

### -AlwaysKeep

Force keeping this event regardless of sampling.


## Outputs

System.Object. Result from ScriptBlock execution.


## Examples

### Example 1

```powershell
Invoke-WithWideEvent -OperationName "aws.s3.upload" -Context @{
```

bucket = "my-bucket" key = "file.txt" } -ScriptBlock { aws s3 cp file.txt s3://my-bucket/file.txt }

## Source

Defined in: ../profile.d/bootstrap/ErrorHandlingStandard.ps1
