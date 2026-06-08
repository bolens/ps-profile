# ConvertTo-IsbnNormalized

## Synopsis

Normalizes and validates an ISBN from any supported format.

## Description

Accepts ISBN-10, ISBN-13, SBN (9-digit), and common prefixed or separated forms such as "ISBN-13: 978-0-306-40615-7" or "0 306 40615 2".

## Signature

```powershell
ConvertTo-IsbnNormalized
```

## Parameters

### -Isbn

The ISBN value to normalize.

### -Strict

When set, invalid checksums cause an error instead of returning IsValid = $false.


## Outputs

PSCustomObject with Input, Digits, Format, Isbn10, Isbn13, IsValid, and IsValidChecksum.


## Examples

### Example 1

`powershell
ConvertTo-IsbnNormalized -Isbn "978-0-306-40615-7"
``

### Example 2

`powershell
ConvertTo-IsbnNormalized -Isbn "ISBN-10: 0-306-40615-2"
``

## Aliases

This function has the following aliases:

- `isbn-normalize` - Normalizes and validates an ISBN from any supported format.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-isbn.ps1
