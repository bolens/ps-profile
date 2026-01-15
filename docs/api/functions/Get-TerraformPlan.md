# Get-TerraformPlan

## Synopsis

Creates a Terraform execution plan.

## Description

Wrapper for terraform plan command.

## Signature

```powershell
Get-TerraformPlan
```

## Parameters

### -Arguments

Arguments to pass to terraform plan.


## Examples

### Example 1

`powershell
Get-TerraformPlan
``

### Example 2

`powershell
Get-TerraformPlan -out=tfplan
``

## Aliases

This function has the following aliases:

- `tfp` - Creates a Terraform execution plan.


## Source

Defined in: ..\profile.d\terraform.ps1
