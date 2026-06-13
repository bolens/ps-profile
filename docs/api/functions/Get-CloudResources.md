# Get-CloudResources

## Synopsis

Lists cloud provider resources using service/action pattern.

## Description

Base function for listing cloud provider resources. Supports: - Service/Action pattern (AWS style) - Direct command pattern (Azure/GCloud style) - JSON parsing and error handling

## Signature

```powershell
Get-CloudResources
```

## Parameters

### -CommandName

CLI command name (e.g., 'aws', 'az', 'gcloud').

### -Service

Service name (e.g., 'ec2', 's3', 'compute'). Optional for direct command pattern.

### -Action

Action name (e.g., 'describe-instances', 'list-buckets', 'list'). Optional for direct command pattern.

### -Arguments

Direct arguments (alternative to Service/Action pattern).

### -OperationName

Operation name for event tracking.

### -Context

Additional context for event tracking.


## Outputs

System.Object. Resource list (parsed JSON or raw output).


## Examples

### Example 1

```powershell
Get-CloudResources -CommandName 'aws' -Service 'ec2' -Action 'describe-instances' -OperationName 'aws.ec2.list'
```

Lists EC2 instances.

## Source

Defined in: ../profile.d/bootstrap/CloudProviderBase.ps1
