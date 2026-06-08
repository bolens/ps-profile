# Format-Isbn

## Synopsis

Formats a normalized ISBN with standard hyphen groups.

## Description

Formats ISBN-10 as 1-3-5-1 groups and ISBN-13 as 3-1-3-5-1 groups when possible.

## Signature

```powershell
Format-Isbn
```

## Parameters

### -Isbn

The ISBN value to format.

### -Format

Target format: Auto, ISBN-10, or ISBN-13.


## Outputs

System.String


## Examples

### Example 1

`powershell
Format-Isbn -Isbn "9780306406157"
``

## Aliases

This function has the following aliases:

- `isbn-format` - Formats a normalized ISBN with standard hyphen groups.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-isbn.ps1
