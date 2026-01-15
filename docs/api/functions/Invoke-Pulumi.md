# Invoke-Pulumi

## Synopsis

Executes Pulumi commands.

## Description

Wrapper function for Pulumi, an infrastructure as code tool that supports multiple programming languages.

## Signature

```powershell
Invoke-Pulumi
```

## Parameters

### -Arguments

Arguments to pass to pulumi.


## Examples

### Example 1

`powershell
Invoke-Pulumi preview
        
        Previews Pulumi changes.
``

### Example 2

`powershell
Invoke-Pulumi up --yes
        
        Applies Pulumi changes automatically.
``

## Source

Defined in: ..\profile.d\iac-tools.ps1
