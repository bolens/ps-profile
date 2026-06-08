# ConvertFrom-QueryStringToJson

## Synopsis

Converts query string file to JSON format.

## Description

Parses a query string from a file and converts it to structured JSON format.

## Signature

```powershell
ConvertFrom-QueryStringToJson
```

## Parameters

### -InputPath

The path to the file containing the query string (.query or .qs extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertFrom-QueryStringToJson -InputPath "query.query"
```

Converts query.query to query.json.

## Aliases

This function has the following aliases:

- `query-to-json` - Converts query string file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-query-string.ps1
