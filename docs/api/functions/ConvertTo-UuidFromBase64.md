# ConvertTo-UuidFromBase64

## Synopsis

Converts a Base64 string to UUID format.

## Description

Converts a Base64 encoded string to standard UUID format.

## Signature

```powershell
ConvertTo-UuidFromBase64 [String]$Base64
```

## Parameters

### -Base64

**Type:** [String]

**Attributes:** Mandatory

The Base64 string to convert.


## Outputs

System.String Returns the UUID in standard format with dashes.


## Examples

### Example 1

```powershell
"VQ6EAOKbQdSnFkRmVVQAAA==" | ConvertTo-UuidFromBase64
```

Converts Base64 to UUID format.

## Aliases

This function has the following aliases:

- `base64-to-uuid` - Converts a Base64 string to UUID format.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/uuid.ps1
