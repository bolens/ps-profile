# ConvertFrom-BinaryToUrl

## Synopsis

Converts binary string to URL/percent encoded representation.

## Description

Converts a binary string to URL/percent encoded string representation.

## Signature

```powershell
ConvertFrom-BinaryToUrl
```

## Parameters

### -InputObject

The binary string to convert. Can be piped. Spaces are automatically removed.


## Outputs

System.String The URL/percent encoded representation of the input binary string.


## Examples

### Example 1

```powershell
"01001000 01101001" | ConvertFrom-BinaryToUrl
```

Converts binary to URL encoding.

## Aliases

This function has the following aliases:

- `binary-to-url` - Converts binary string to URL/percent encoded representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/binary.ps1
