# ConvertTo-AccessFromJson

## Synopsis

Converts JSON file to Microsoft Access database format.

## Description

Converts a JSON file to Microsoft Access database format (.mdb or .accdb). Note: Creating new Access databases programmatically is complex and may not be fully supported. Requires Python with pyodbc package and Microsoft Access Database Engine (ACE) to be installed.

## Signature

```powershell
ConvertTo-AccessFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output Access database file. If not specified, uses input path with .accdb extension.

### -Format

Optional. Format to create: 'accdb' (default) or 'mdb'.


## Examples

### Example 1

`powershell
ConvertTo-AccessFromJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `json-to-accdb` - Converts JSON file to Microsoft Access database format.
- `json-to-access` - Converts JSON file to Microsoft Access database format.
- `json-to-mdb` - Converts JSON file to Microsoft Access database format.


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-access.ps1
