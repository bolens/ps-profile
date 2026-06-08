# ConvertTo-GuidFromBase64

## Synopsis

Converts a Base64 string to GUID format.

## Description

Converts a Base64 encoded string to standard GUID format.

## Signature

```powershell
ConvertTo-GuidFromBase64 [String]$Base64, [SwitchParameter]$RegistryFormat
```

## Parameters

### -Base64

**Type:** [String]

The Base64 string to convert.

### -RegistryFormat

**Type:** [SwitchParameter]

Return the GUID in Windows registry format with braces.


## Outputs

System.String Returns the GUID in standard format (or registry format if specified).


## Examples

### Example 1

`powershell
"VQ6EAOKbQdSnFkRmVVQAAA==" | ConvertTo-GuidFromBase64
    
    Converts Base64 to GUID format.
``

## Aliases

This function has the following aliases:

- `base64-to-guid` - Converts a Base64 string to GUID format.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/guid.ps1
