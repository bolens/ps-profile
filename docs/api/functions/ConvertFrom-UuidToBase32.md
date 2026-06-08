# ConvertFrom-UuidToBase32

## Synopsis

Converts a UUID to Base32 format.

## Description

Converts a UUID string to Base32 encoded format.

## Signature

```powershell
ConvertFrom-UuidToBase32 [String]$Uuid
```

## Parameters

### -Uuid

**Type:** [String]

**Attributes:** Mandatory

The UUID string to convert.


## Outputs

System.String Returns the UUID in Base32 format.


## Examples

### Example 1

```powershell
"550e8400-e29b-41d4-a716-446655440000" | ConvertFrom-UuidToBase32
```

Converts UUID to Base32 format.

## Aliases

This function has the following aliases:

- `uuid-to-base32` - Converts a UUID to Base32 format.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/uuid.ps1
