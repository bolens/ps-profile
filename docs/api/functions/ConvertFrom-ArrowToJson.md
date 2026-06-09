# ConvertFrom-ArrowToJson

## Synopsis

Converts Arrow file to JSON format.

## Description

Converts an Apache Arrow columnar file back to JSON format. Requires Node.js and the apache-arrow package to be installed.

## Signature

```powershell
ConvertFrom-ArrowToJson
```

## Parameters

### -InputPath

The path to the Arrow file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-ArrowToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `arrow-to-json` - Converts Arrow file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/columnar/columnar-arrow.ps1
