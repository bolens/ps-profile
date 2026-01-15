# Invoke-TerraformApply

## Synopsis

Applies Terraform changes.

## Description

Wrapper for terraform apply command.

## Signature

```powershell
Invoke-TerraformApply
```

## Parameters

### -Arguments

Arguments to pass to terraform apply.


## Examples

### Example 1

`powershell
Invoke-TerraformApply
``

### Example 2

`powershell
Invoke-TerraformApply -auto-approve
``

## Aliases

This function has the following aliases:

- `tfa` - Applies Terraform changes.


## Source

Defined in: ..\profile.d\terraform.ps1
