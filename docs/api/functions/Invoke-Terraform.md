# Invoke-Terraform

## Synopsis

Executes terraform with the specified arguments.

## Description

Wrapper function for terraform that checks for command availability before execution.

## Signature

```powershell
Invoke-Terraform
```

## Parameters

### -Arguments

Arguments to pass to terraform.


## Examples

### Example 1

`powershell
Invoke-Terraform version
``

### Example 2

`powershell
Invoke-Terraform init
``

## Aliases

This function has the following aliases:

- `tf` - Executes terraform with the specified arguments.


## Source

Defined in: ..\profile.d\terraform.ps1
