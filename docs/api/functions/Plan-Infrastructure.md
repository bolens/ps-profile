# Plan-Infrastructure

## Synopsis

Plans infrastructure changes.

## Description

Creates an execution plan for infrastructure changes using Terraform or OpenTofu. Prefers Terraform, falls back to OpenTofu if Terraform is not available.

## Signature

```powershell
Plan-Infrastructure
```

## Parameters

### -Tool

Tool to use: terraform, opentofu, auto. Defaults to auto (prefers terraform).

### -OutputFile

Optional file to save the plan to.

### -Arguments

Additional arguments to pass to the plan command.


## Outputs

System.String. Plan output.


## Examples

### Example 1

`powershell
Plan-Infrastructure
        
        Creates a plan using the default tool (Terraform).
``

### Example 2

`powershell
Plan-Infrastructure -OutputFile "plan.out" -Tool "opentofu"
        
        Creates a plan using OpenTofu and saves to plan.out.
``

## Source

Defined in: ..\profile.d\iac-tools.ps1
