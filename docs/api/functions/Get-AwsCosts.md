# Get-AwsCosts

## Synopsis

Gets AWS cost information.

## Description

Retrieves AWS cost information using AWS Cost Explorer API or billing commands. Requires appropriate IAM permissions.

## Signature

```powershell
Get-AwsCosts
```

## Parameters

### -StartDate

Start date for cost query (YYYY-MM-DD format). Defaults to first day of current month.

### -EndDate

End date for cost query (YYYY-MM-DD format). Defaults to today.

### -Service

Optional service name to filter costs (e.g., 'EC2', 'S3', 'Lambda').


## Outputs

System.Object. Cost information from AWS.


## Examples

### Example 1

`powershell
Get-AwsCosts
    
    Gets costs for the current month.
``

### Example 2

`powershell
Get-AwsCosts -StartDate "2024-01-01" -EndDate "2024-01-31" -Service "EC2"
    
    Gets EC2 costs for January 2024.
``

## Source

Defined in: ..\profile.d\aws.ps1
