# ConvertTo-UuidFromBase32

## Synopsis

Converts a Base32 string to UUID format.

## Description

Converts a Base32 encoded string to standard UUID format.

## Signature

```powershell
ConvertTo-UuidFromBase32 [String]$Base32
```

## Parameters

### -Base32

**Type:** [String]

**Attributes:** Mandatory

The Base32 string to convert.


## Outputs

System.String Returns the UUID in standard format with dashes.


## Examples

### Example 1

```powershell
"K5VQK4VQK4VQK4VQK4VQK4VQ" | ConvertTo-UuidFromBase32
```

Converts Base32 to UUID format.

## Aliases

This function has the following aliases:

- `base32-to-uuid` - Converts a Base32 string to UUID format.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/uuid.ps1
