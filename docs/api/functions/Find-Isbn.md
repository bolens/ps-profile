# Find-Isbn

## Synopsis

Searches for books by title and/or author.

## Description

Queries Open Library and Google Books, returning normalized book records. Use -Pick to choose a result in Out-GridView when available.

## Signature

```powershell
Find-Isbn
```

## Parameters

### -Title

Book title search text.

### -Author

Author name search text.

### -Limit

Maximum number of results per provider.

### -Provider

Metadata provider to query.

### -Pick

Prompts for a single selected result.


## Outputs

PSCustomObject[]


## Examples

### Example 1

```powershell
Find-Isbn -Title 'Dune' -Author 'Herbert'
```

## Aliases

This function has the following aliases:

- `isbn-find` - Searches for books by title and/or author.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-isbn-extended.ps1
