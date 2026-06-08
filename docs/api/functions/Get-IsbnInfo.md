# Get-IsbnInfo

## Synopsis

Looks up book metadata by ISBN.

## Description

Accepts ISBN-10, ISBN-13, SBN, and common prefixed or separated forms. Queries Open Library first, then Google Books as a fallback. Results are cached locally unless -Refresh is specified.

## Signature

```powershell
Get-IsbnInfo
```

## Parameters

### -Isbn

The ISBN to look up. Supports pipeline input for batch lookups.

### -Provider

Data provider: Auto, OpenLibrary, GoogleBooks, OpenBD, or LibraryOfCongress.

### -OutputFormat

Output format: Object, Text, Json, BibTeX, Ris, CslJson, Apa, Mla, Chicago, Table, or Csv.

### -Refresh

Bypass cached lookup results and fetch fresh metadata.

### -Offline

Return cached metadata only and do not query remote providers.


## Outputs

PSCustomObject, System.String


## Examples

### Example 1

`powershell
Get-IsbnInfo -Isbn "978-0-306-40615-7"
``

### Example 2

`powershell
Get-IsbnInfo -Isbn "ISBN-10: 0-306-40615-2" -OutputFormat BibTeX
``

### Example 3

`powershell
Get-Content isbns.txt | Get-IsbnInfo -OutputFormat Table
``

## Aliases

This function has the following aliases:

- `isbn` - Looks up book metadata by ISBN.
- `isbn-lookup` - Looks up book metadata by ISBN.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-isbn.ps1
