# ConvertFrom-SqliteToJson

## Synopsis

Converts SQLite database to JSON format.

## Description

Converts a SQLite database file to JSON format. Exports table data from SQLite database. Requires SQLite command-line tool (sqlite3) or .NET System.Data.SQLite to be installed.

## Signature

```powershell
ConvertFrom-SqliteToJson
```

## Parameters

### -InputPath

The path to the SQLite database file (.db, .sqlite, or .sqlite3 extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.

### -TableName

Optional. Name of the table to export. If not specified, exports all tables.


## Examples

### Example 1

`powershell
ConvertFrom-SqliteToJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `db-to-json` - Converts SQLite database to JSON format.
- `sqlite-to-json` - Converts SQLite database to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-sqlite.ps1
