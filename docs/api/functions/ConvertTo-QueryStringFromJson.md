# ConvertTo-QueryStringFromJson

## Synopsis

Converts JSON file to query string format.

## Description

Converts a structured JSON file (with key-value pairs) to query string format.

## Signature

```powershell
ConvertTo-QueryStringFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output query string file. If not specified, uses input path with .query extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertTo-QueryStringFromJson -InputPath "params.json"
```

Converts params.json to params.query.

## Aliases

This function has the following aliases:

- `json-to-query` - Converts JSON file to query string format.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-query-string.ps1
