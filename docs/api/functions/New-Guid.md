# New-Guid

## Synopsis

Generates a new GUID (Globally Unique Identifier).

## Description

Generates a new GUID using .NET Guid.NewGuid(). Can return the GUID in various formats.

## Signature

```powershell
New-Guid [SwitchParameter]$RegistryFormat, [SwitchParameter]$AsHex, [SwitchParameter]$AsBase64
```

## Parameters

### -RegistryFormat

**Type:** [SwitchParameter]

Return the GUID in Windows registry format with braces.

### -AsHex

**Type:** [SwitchParameter]

Return the GUID as hexadecimal string without dashes.

### -AsBase64

**Type:** [SwitchParameter]

Return the GUID as Base64 encoded string.


## Outputs

System.String Returns a new GUID in the specified format.


## Examples

### Example 1

`powershell
New-Guid
    
    Generates a new GUID in standard format.
``

### Example 2

`powershell
New-Guid -RegistryFormat
    
    Generates a new GUID in Windows registry format.
``

### Example 3

`powershell
New-Guid -AsHex
    
    Generates a new GUID in hexadecimal format.
``

## Source

Defined in: ../profile.d/conversion-modules/data/encoding/guid.ps1
