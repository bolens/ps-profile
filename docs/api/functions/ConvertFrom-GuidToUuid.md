# ConvertFrom-GuidToUuid

## Synopsis

Converts a GUID to UUID format.

## Description

Converts a GUID string to UUID format (they're the same format, just different names).

## Signature

```powershell
ConvertFrom-GuidToUuid [String]$Guid
```

## Parameters

### -Guid

**Type:** [String]

The GUID string to convert.


## Outputs

System.String Returns the GUID as a UUID string.


## Examples

### Example 1

`powershell
"550e8400-e29b-41d4-a716-446655440000" | ConvertFrom-GuidToUuid
    
    Converts GUID to UUID format (same format).
``

## Aliases

This function has the following aliases:

- `guid-to-uuid` - Converts a GUID to UUID format.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/guid.ps1
