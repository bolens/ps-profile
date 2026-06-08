# ConvertTo-EdnFromJson

## Synopsis

Converts JSON file to EDN format.

## Description

Converts a JSON file to EDN (Extensible Data Notation) format. EDN is a data format used in Clojure, similar to JSON but with more data types.

## Signature

```powershell
ConvertTo-EdnFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output EDN file. If not specified, uses input path with .edn extension.


## Examples

### Example 1

```powershell
ConvertTo-EdnFromJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `json-to-edn` - Converts JSON file to EDN format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/edn.ps1
