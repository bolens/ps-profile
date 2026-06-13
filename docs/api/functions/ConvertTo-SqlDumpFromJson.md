# ConvertTo-SqlDumpFromJson

## Synopsis

Converts JSON file to SQL dump format.

## Description

Converts a JSON file to SQL dump format. Creates SQL CREATE TABLE and INSERT statements from JSON data. Pure PowerShell implementation - no external dependencies required.

## Signature

```powershell
ConvertTo-SqlDumpFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output SQL dump file. If not specified, uses input path with .sql extension.


## Examples

### Example 1

```powershell
ConvertTo-SqlDumpFromJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `json-to-sql` - Converts JSON file to SQL dump format.
- `json-to-sql-dump` - Converts JSON file to SQL dump format.


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-sql-dump.ps1
