# Invoke-OpenTofu

## Synopsis

Executes OpenTofu commands.

## Description

Wrapper function for OpenTofu, an open-source fork of Terraform. Provides the same interface as Terraform with open-source licensing.

## Signature

```powershell
Invoke-OpenTofu
```

## Parameters

### -Arguments

Arguments to pass to opentofu.


## Examples

### Example 1

`powershell
Invoke-OpenTofu init
        
        Initializes OpenTofu working directory.
``

### Example 2

`powershell
Invoke-OpenTofu plan
        
        Creates an OpenTofu execution plan.
``

## Source

Defined in: ..\profile.d\iac-tools.ps1
