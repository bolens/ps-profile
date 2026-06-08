# Get-IsbnEditions

## Synopsis

Lists alternate editions for a book ISBN.

## Description

Resolves the Open Library work for an ISBN and returns edition metadata rows.

## Signature

```powershell
Get-IsbnEditions
```

## Parameters

### -Isbn

ISBN used to locate the work.

### -Limit

Maximum number of editions to return.


## Outputs

PSCustomObject[]


## Examples

### Example 1

```powershell
Get-IsbnEditions -Isbn '9780441172719'
```

## Aliases

This function has the following aliases:

- `isbn-editions` - Lists alternate editions for a book ISBN.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-isbn-extended.ps1
