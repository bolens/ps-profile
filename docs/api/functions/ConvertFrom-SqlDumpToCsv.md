# ConvertFrom-SqlDumpToCsv

## Synopsis

Converts SQL dump file to CSV format.

## Description

Converts a SQL dump file to CSV format. Parses SQL INSERT statements to extract data and convert to CSV. Pure PowerShell implementation - no external dependencies required.

## Signature

```powershell
ConvertFrom-SqlDumpToCsv
```

## Parameters

### -InputPath

The path to the SQL dump file (.sql extension).

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.

### -TableName

Optional. Name of the table to export. If not specified, exports the first table found.


## Examples

### Example 1

```powershell
ConvertFrom-SqlDumpToCsv -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `sql-dump-to-csv` - Converts SQL dump file to CSV format.
- `sql-to-csv` - Converts SQL dump file to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-sql-dump.ps1
