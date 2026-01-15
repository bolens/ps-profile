# Get-AwsResources

## Synopsis

Lists AWS resources by type.

## Description

Retrieves a list of AWS resources of a specified type using AWS CLI. Supports common resource types like EC2 instances, S3 buckets, etc.

## Signature

```powershell
Get-AwsResources
```

## Parameters

### -ResourceType

AWS resource type (e.g., 'ec2', 's3', 'lambda', 'rds').

### -Service

AWS service name (e.g., 'ec2', 's3', 'lambda').

### -Action

Service action to list resources (e.g., 'describe-instances', 'list-buckets').


## Outputs

System.Object. Resource list from AWS CLI.


## Examples

### Example 1

`powershell
Get-AwsResources -Service 'ec2' -Action 'describe-instances'
    
    Lists EC2 instances.
``

### Example 2

`powershell
Get-AwsResources -Service 's3' -Action 'list-buckets'
    
    Lists S3 buckets.
``

## Source

Defined in: ..\profile.d\aws.ps1
