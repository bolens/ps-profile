# ConvertTo-ArrowFromJson

## Synopsis

Converts JSON file to Arrow format.

## Description

Converts a JSON file to Apache Arrow columnar format. Requires Node.js and the apache-arrow package to be installed. Note: Arrow conversion requires table construction.

## Signature

```powershell
ConvertTo-ArrowFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output Arrow file. If not specified, uses input path with .arrow extension.


## Examples

### Example 1

`powershell
ConvertTo-ArrowFromJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `json-to-arrow` - Converts JSON file to Arrow format.


## Source

Defined in: ../profile.d/conversion-modules/data/columnar/columnar-arrow.ps1
