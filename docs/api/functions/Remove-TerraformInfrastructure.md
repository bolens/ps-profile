# Remove-TerraformInfrastructure

## Synopsis

Destroys Terraform-managed infrastructure.

## Description

Wrapper for terraform destroy command.

## Signature

```powershell
Remove-TerraformInfrastructure
```

## Parameters

### -Arguments

Arguments to pass to terraform destroy.


## Examples

### Example 1

`powershell
Remove-TerraformInfrastructure
``

### Example 2

`powershell
Remove-TerraformInfrastructure -auto-approve
``

## Aliases

This function has the following aliases:

- `tfd` - Destroys Terraform-managed infrastructure.


## Source

Defined in: ..\profile.d\18-terraform.ps1
