# Apply-Infrastructure

## Synopsis

Applies infrastructure changes.

## Description

Applies infrastructure changes using Terraform or OpenTofu. Prefers Terraform, falls back to OpenTofu if Terraform is not available.

## Signature

```powershell
Apply-Infrastructure
```

## Parameters

### -Tool

Tool to use: terraform, opentofu, auto. Defaults to auto (prefers terraform).

### -PlanFile

Optional plan file to apply.

### -AutoApprove

Automatically approve the apply without prompting.

### -Arguments

Additional arguments to pass to the apply command.


## Outputs

System.String. Apply output.


## Examples

### Example 1

`powershell
Apply-Infrastructure
        
        Applies infrastructure changes using the default tool.
``

### Example 2

`powershell
Apply-Infrastructure -PlanFile "plan.out" -AutoApprove
        
        Applies a specific plan file automatically.
``

## Source

Defined in: ..\profile.d\iac-tools.ps1
