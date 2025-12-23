# Set-AwsRegion

## Synopsis

Sets the AWS region environment variable.

## Description

Sets the AWS_REGION environment variable to the specified region.

## Signature

```powershell
Set-AwsRegion
```

## Parameters

### -Region

AWS region name (e.g., "us-east-1", "eu-west-1").


## Examples

### Example 1

`powershell
Set-AwsRegion -Region "us-east-1"
``

### Example 2

`powershell
Set-AwsRegion -Region "eu-west-1"
``

## Aliases

This function has the following aliases:

- `aws-region` - Sets the AWS region environment variable.


## Source

Defined in: ..\profile.d\31-aws.ps1
