# ConvertFrom-Base32ToUrl

## Synopsis

Converts Base32 string to URL/percent encoded representation.

## Description

Converts a Base32 string to URL/percent encoded string representation.

## Signature

```powershell
ConvertFrom-Base32ToUrl
```

## Parameters

### -InputObject

The Base32 string to convert. Can be piped.


## Outputs

System.String The URL/percent encoded representation of the input Base32 string.


## Examples

### Example 1

```powershell
"JBSWY3DP" | ConvertFrom-Base32ToUrl
```

Converts Base32 to URL encoding.

## Aliases

This function has the following aliases:

- `base32-to-url` - Converts Base32 string to URL/percent encoded representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base32.ps1
