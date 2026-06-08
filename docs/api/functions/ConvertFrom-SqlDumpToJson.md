# ConvertFrom-SqlDumpToJson

## Synopsis

Converts SQL dump file to JSON format.

## Description

Converts a SQL dump file to JSON format. Parses SQL CREATE TABLE and INSERT statements to extract data. Pure PowerShell implementation - no external dependencies required.

## Signature

```powershell
ConvertFrom-SqlDumpToJson
```

## Parameters

### -InputPath

The path to the SQL dump file (.sql extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-SqlDumpToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `sql-dump-to-json` - Converts SQL dump file to JSON format.
- `sql-to-json` - Converts SQL dump file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-sql-dump.ps1
