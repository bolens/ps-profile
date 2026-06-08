# ConvertFrom-GuidToRegistryFormat

## Synopsis

Converts a GUID to Windows registry format.

## Description

Converts a GUID string to Windows registry format with braces.

## Signature

```powershell
ConvertFrom-GuidToRegistryFormat [String]$Guid
```

## Parameters

### -Guid

**Type:** [String]

The GUID string to convert.


## Outputs

System.String Returns the GUID in Windows registry format with braces.


## Examples

### Example 1

`powershell
"550e8400-e29b-41d4-a716-446655440000" | ConvertFrom-GuidToRegistryFormat
    
    Converts GUID to registry format: "{550e8400-e29b-41d4-a716-446655440000}"
``

## Aliases

This function has the following aliases:

- `guid-to-registry` - Converts a GUID to Windows registry format.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/guid.ps1
