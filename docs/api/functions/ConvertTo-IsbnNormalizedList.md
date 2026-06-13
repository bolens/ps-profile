# ConvertTo-IsbnNormalizedList

## Synopsis

Normalizes and deduplicates a list of ISBN values.

## Description

Accepts pipeline input, normalizes each ISBN, and returns unique records.

## Signature

```powershell
ConvertTo-IsbnNormalizedList
```

## Parameters

### -Isbn

ISBN value from the pipeline.


## Outputs

PSCustomObject[]


## Examples

### Example 1

```powershell
'9780306406157', '0-306-40615-2' | ConvertTo-IsbnNormalizedList
```

## Aliases

This function has the following aliases:

- `isbn-dedupe` - Normalizes and deduplicates a list of ISBN values.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-isbn-extended.ps1
