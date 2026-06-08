# ConvertFrom-AccessToJson

## Synopsis

Converts Microsoft Access database to JSON format.

## Description

Converts a Microsoft Access database file (.mdb or .accdb) to JSON format. Exports table data from Access database. Requires Python with pyodbc package and Microsoft Access Database Engine (ACE) to be installed.

## Signature

```powershell
ConvertFrom-AccessToJson
```

## Parameters

### -InputPath

The path to the Access database file (.mdb or .accdb extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.

### -TableName

Optional. Name of the table to export. If not specified, exports all tables.


## Examples

### Example 1

`powershell
ConvertFrom-AccessToJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `accdb-to-json` - Converts Microsoft Access database to JSON format.
- `access-to-json` - Converts Microsoft Access database to JSON format.
- `mdb-to-json` - Converts Microsoft Access database to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-access.ps1
