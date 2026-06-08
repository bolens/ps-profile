# ConvertTo-SqliteFromJson

## Synopsis

Converts JSON file to SQLite database format.

## Description

Converts a JSON file to SQLite database format. Creates a SQLite database with tables based on JSON structure. Requires SQLite command-line tool (sqlite3) to be installed.

## Signature

```powershell
ConvertTo-SqliteFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output SQLite database file. If not specified, uses input path with .db extension.

### -TableName

Optional. Name of the table to create. Defaults to 'data'. Ignored if JSON contains multiple tables.


## Examples

### Example 1

`powershell
ConvertTo-SqliteFromJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `json-to-db` - Converts JSON file to SQLite database format.
- `json-to-sqlite` - Converts JSON file to SQLite database format.


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-sqlite.ps1
