# Import-IsbnListFile

## Synopsis

Imports ISBN values from a text file and optionally looks them up.

## Description

Imports ISBN values from a text file and optionally looks them up.

## Signature

```powershell
Import-IsbnListFile
```

## Parameters

### -Path

Text file containing ISBN values.

### -Lookup

Performs metadata lookups for extracted ISBN values.

### -OutputFormat

Output format when -Lookup is specified.

### -Provider

Metadata provider used during lookup.

### -OutputPath

Optional file path for exported lookup output.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `isbn-import` - Imports ISBN values from a text file and optionally looks them up.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-isbn-extended.ps1
