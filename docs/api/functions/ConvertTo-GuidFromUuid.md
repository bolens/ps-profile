# ConvertTo-GuidFromUuid

## Synopsis

Converts a UUID to GUID format.

## Description

Converts a UUID string to GUID format (they're the same format, just different names).

## Signature

```powershell
ConvertTo-GuidFromUuid [String]$Uuid, [SwitchParameter]$RegistryFormat
```

## Parameters

### -Uuid

**Type:** [String]

The UUID string to convert.

### -RegistryFormat

**Type:** [SwitchParameter]

Return the GUID in Windows registry format with braces.


## Outputs

System.String Returns the UUID as a GUID string.


## Examples

### Example 1

`powershell
"550e8400-e29b-41d4-a716-446655440000" | ConvertTo-GuidFromUuid
    
    Converts UUID to GUID format (same format).
``

## Aliases

This function has the following aliases:

- `uuid-to-guid` - Converts a UUID to GUID format.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/guid.ps1
