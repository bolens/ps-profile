# ConvertFrom-GuidToBase64

## Synopsis

Converts a GUID to Base64 format.

## Description

Converts a GUID string to Base64 encoded format.

## Signature

```powershell
ConvertFrom-GuidToBase64 [String]$Guid
```

## Parameters

### -Guid

**Type:** [String]

The GUID string to convert.


## Outputs

System.String Returns the GUID in Base64 format.


## Examples

### Example 1

`powershell
"550e8400-e29b-41d4-a716-446655440000" | ConvertFrom-GuidToBase64
    
    Converts GUID to Base64 format.
``

## Aliases

This function has the following aliases:

- `guid-to-base64` - Converts a GUID to Base64 format.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/guid.ps1
