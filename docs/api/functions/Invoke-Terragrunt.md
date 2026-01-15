# Invoke-Terragrunt

## Synopsis

Executes Terragrunt commands.

## Description

Wrapper function for Terragrunt, a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules.

## Signature

```powershell
Invoke-Terragrunt
```

## Parameters

### -Arguments

Arguments to pass to terragrunt.


## Examples

### Example 1

`powershell
Invoke-Terragrunt plan
        
        Runs terragrunt plan.
``

### Example 2

`powershell
Invoke-Terragrunt apply -auto-approve
        
        Applies Terragrunt changes automatically.
``

## Source

Defined in: ..\profile.d\iac-tools.ps1
