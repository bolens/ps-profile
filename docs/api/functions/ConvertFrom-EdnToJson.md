# ConvertFrom-EdnToJson

## Synopsis

Converts EDN file to JSON format.

## Description

Converts an EDN (Extensible Data Notation) file to JSON format. EDN is a data format used in Clojure, similar to JSON but with more data types.

## Signature

```powershell
ConvertFrom-EdnToJson
```

## Parameters

### -InputPath

The path to the EDN file (.edn extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-EdnToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `edn-to-json` - Converts EDN file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/edn.ps1
