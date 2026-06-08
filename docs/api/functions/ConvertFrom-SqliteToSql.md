# ConvertFrom-SqliteToSql

## Synopsis

Converts SQLite database to SQL dump format.

## Description

Converts a SQLite database file to SQL dump format. Creates a SQL script that can recreate the database. Requires SQLite command-line tool (sqlite3) to be installed.

## Signature

```powershell
ConvertFrom-SqliteToSql
```

## Parameters

### -InputPath

The path to the SQLite database file (.db, .sqlite, or .sqlite3 extension).

### -OutputPath

The path for the output SQL file. If not specified, uses input path with .sql extension.


## Examples

### Example 1

`powershell
ConvertFrom-SqliteToSql -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `db-to-sql` - Converts SQLite database to SQL dump format.
- `sqlite-to-sql` - Converts SQLite database to SQL dump format.


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-sqlite.ps1
