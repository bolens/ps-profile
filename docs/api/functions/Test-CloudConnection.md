# Test-CloudConnection

## Synopsis

Tests connection to cloud provider.

## Description

Base function for testing cloud provider connections. Executes a validation command and parses the response.

## Signature

```powershell
Test-CloudConnection
```

## Parameters

### -CommandName

CLI command name (e.g., 'aws', 'az', 'gcloud').

### -TestCommand

Command to test connection (e.g., 'sts get-caller-identity', 'account show').

### -ParseJson

Parse response as JSON (default: $true).

### -SuccessIndicator

Property path to check for success (e.g., 'Account', 'id'). If provided, checks if this property exists in the response.

### -OperationName

Operation name for event tracking.

### -Context

Additional context for event tracking.


## Outputs

System.Boolean. True if connection successful, false otherwise.


## Examples

### Example 1

```powershell
Test-CloudConnection -CommandName 'aws' -TestCommand @('sts', 'get-caller-identity') -SuccessIndicator 'Account'
```

Tests AWS connection by checking caller identity.

## Source

Defined in: ../profile.d/bootstrap/CloudProviderBase.ps1
