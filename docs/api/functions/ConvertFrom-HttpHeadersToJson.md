# ConvertFrom-HttpHeadersToJson

## Synopsis

Converts HTTP headers file to JSON format.

## Description

Parses HTTP headers from a file and converts them to structured JSON format.

## Signature

```powershell
ConvertFrom-HttpHeadersToJson
```

## Parameters

### -InputPath

The path to the file containing HTTP headers (.headers or .http extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertFrom-HttpHeadersToJson -InputPath "headers.headers"
    
    Converts headers.headers to headers.json.
``

## Aliases

This function has the following aliases:

- `headers-to-json` - Converts HTTP headers file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-http-headers.ps1
