# ConvertFrom-SqliteToCsv

## Synopsis

Converts SQLite database to CSV format.

## Description

Converts a SQLite database file to CSV format. Exports table data from SQLite database. Requires SQLite command-line tool (sqlite3) to be installed.

## Signature

```powershell
ConvertFrom-SqliteToCsv
```

## Parameters

### -InputPath

The path to the SQLite database file (.db, .sqlite, or .sqlite3 extension).

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.

### -TableName

Optional. Name of the table to export. If not specified, exports the first table.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `db-to-csv` - Converts SQLite database to CSV format.
- `sqlite-to-csv` - Converts SQLite database to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-sqlite.ps1
