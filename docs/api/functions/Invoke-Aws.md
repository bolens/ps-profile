# Invoke-Aws

## Synopsis

Executes AWS CLI commands.

## Description

Wrapper function for AWS CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Aws
```

## Parameters

### -Arguments

Arguments to pass to aws.


## Examples

### Example 1

`powershell
Invoke-Aws s3 ls
``

### Example 2

`powershell
Invoke-Aws ec2 describe-instances
``

## Aliases

This function has the following aliases:

- `aws` - Executes AWS CLI commands.


## Source

Defined in: ..\profile.d\31-aws.ps1
