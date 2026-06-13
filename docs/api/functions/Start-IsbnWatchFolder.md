# Start-IsbnWatchFolder

## Synopsis

Watches a folder for new files containing ISBN values and processes them.

## Description

Watches a folder for new files containing ISBN values and processes them.

## Signature

```powershell
Start-IsbnWatchFolder
```

## Parameters

### -Path

Directory to watch for new files.

### -OutputFormat

Output format for discovered ISBN lookups.

### -Provider

Metadata provider used during lookup.

### -OutputDirectory

Directory where lookup output files are written.

### -OnIsbnFound

Optional script block invoked for each discovered ISBN.


## Outputs

System.IO.FileSystemWatcher


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `isbn-watch` - Watches a folder for new files containing ISBN values and processes them.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-isbn-extended.ps1
