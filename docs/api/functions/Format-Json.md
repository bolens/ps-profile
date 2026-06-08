# Format-Json

## Synopsis

Pretty-prints JSON data.

## Description

Formats JSON data with proper indentation and structure.

## Signature

```powershell
Format-Json
```

## Parameters

### -InputObject

JSON object or string from the pipeline.

### -fileArgs

Optional input file path when not using the pipeline.


## Examples

### Example 1

`powershell
Get-Content ./data.json -Raw | Format-Json
``

### Example 2

`powershell
Format-Json ./data.json
``

## Aliases

This function has the following aliases:

- `json-pretty` - Pretty-prints JSON data.


## Source

Defined in: ../profile.d/conversion-modules/data/core/json.ps1
