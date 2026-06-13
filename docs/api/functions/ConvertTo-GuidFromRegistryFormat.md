# ConvertTo-GuidFromRegistryFormat

## Synopsis

Converts a Windows registry format GUID to standard format.

## Description

Converts a GUID in Windows registry format (with braces) to standard format.

## Signature

```powershell
ConvertTo-GuidFromRegistryFormat [String]$RegistryGuid
```

## Parameters

### -RegistryGuid

**Type:** [String]

The registry format GUID string to convert.


## Outputs

System.String Returns the GUID in standard format without braces.


## Examples

### Example 1

```powershell
"{550e8400-e29b-41d4-a716-446655440000}" | ConvertTo-GuidFromRegistryFormat
```

Converts registry format to standard GUID: "550e8400-e29b-41d4-a716-446655440000"

## Aliases

This function has the following aliases:

- `registry-to-guid` - Converts a Windows registry format GUID to standard format.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/guid.ps1
