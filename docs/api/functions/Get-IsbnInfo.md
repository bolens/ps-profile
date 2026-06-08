# Get-IsbnInfo

## Synopsis

Looks up book metadata by ISBN.

## Description

Accepts ISBN-10, ISBN-13, SBN, and common prefixed or separated forms. Queries Open Library first, then Google Books as a fallback.

## Signature

```powershell
Get-IsbnInfo
```

## Parameters

### -Isbn

The ISBN to look up.

### -Provider

Data provider: Auto, OpenLibrary, or GoogleBooks.

### -OutputFormat

Output format: Object, Text, or Json.


## Outputs

PSCustomObject, System.String


## Examples

### Example 1

`powershell
Get-IsbnInfo -Isbn "978-0-306-40615-7"
``

### Example 2

`powershell
Get-IsbnInfo -Isbn "ISBN-10: 0-306-40615-2" -OutputFormat Json
``

## Aliases

This function has the following aliases:

- `isbn` - Looks up book metadata by ISBN.
- `isbn-lookup` - Looks up book metadata by ISBN.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-isbn.ps1
