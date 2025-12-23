# Convert-JqToJson

## Synopsis

Converts JSON to compact JSON format using jq.

## Description

Uses jq to convert JSON files to compact (single-line) JSON format.

## Signature

```powershell
Convert-JqToJson
```

## Parameters

### -File

Path to the JSON file to convert.


## Examples

### Example 1

`powershell
Convert-JqToJson -File "data.json"
``

### Example 2

`powershell
Convert-JqToJson -File "config.json"
``

## Aliases

This function has the following aliases:

- `jq2json` - Converts JSON to compact JSON format using jq.


## Source

Defined in: ..\profile.d\28-jq-yq.ps1
