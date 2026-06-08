# Test-IsbnValid

## Synopsis

Tests whether an ISBN is valid.

## Description

Returns $true when the input can be parsed and passes ISBN-10 or ISBN-13 checksum validation.

## Signature

```powershell
Test-IsbnValid
```

## Parameters

### -Isbn

The ISBN value to validate.


## Outputs

System.Boolean


## Examples

### Example 1

`powershell
Test-IsbnValid -Isbn "978-0-306-40615-7"
``

## Aliases

This function has the following aliases:

- `isbn-validate` - Tests whether an ISBN is valid.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-isbn.ps1
