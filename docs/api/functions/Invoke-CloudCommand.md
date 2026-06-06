# Invoke-CloudCommand

## Synopsis

Executes a cloud provider CLI command with standardized error handling.

## Description

Base function for executing cloud provider CLI commands. Handles: - Tool detection using Test-CachedCommand - Missing tool warnings - Error handling and output parsing - Wide event tracking (if available)

## Signature

```powershell
Invoke-CloudCommand
```

## Parameters

### -CommandName

Name of the CLI command (e.g., 'aws', 'az', 'gcloud').

### -Arguments

Arguments to pass to the command.

### -OperationName

Operation name for event tracking (e.g., 'aws.s3.upload'). If not provided, defaults to "{CommandName}.{FirstArgument}".

### -Context

Additional context for event tracking.

### -InstallHint

Installation hint for missing tool warning.

### -ParseJson

Attempt to parse output as JSON (default: $true).

### -ErrorOnNonZeroExit

Throw error if command exits with non-zero code (default: $true).


## Outputs

System.Object. Command output (parsed JSON if ParseJson is true, otherwise raw output).


## Examples

### Example 1

`powershell
Invoke-CloudCommand -CommandName 'aws' -Arguments @('s3', 'ls') -OperationName 'aws.s3.list'
        
        Executes 'aws s3 ls' with event tracking.
``

## Source

Defined in: ../profile.d/bootstrap/CloudProviderBase.ps1
