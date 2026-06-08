# ConvertFrom-AccessToCsv

## Synopsis

Converts Microsoft Access database to CSV format.

## Description

Converts a Microsoft Access database file (.mdb or .accdb) to CSV format. Exports table data from Access database. Requires Python with pyodbc package and Microsoft Access Database Engine (ACE) to be installed.

## Signature

```powershell
ConvertFrom-AccessToCsv
```

## Parameters

### -InputPath

The path to the Access database file (.mdb or .accdb extension).

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.

### -TableName

Optional. Name of the table to export. If not specified, exports the first table.


## Examples

### Example 1

```powershell
ConvertFrom-AccessToCsv -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `accdb-to-csv` - Converts Microsoft Access database to CSV format.
- `access-to-csv` - Converts Microsoft Access database to CSV format.
- `mdb-to-csv` - Converts Microsoft Access database to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-access.ps1
