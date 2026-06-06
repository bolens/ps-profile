# ConvertTo-HttpHeadersFromJson

## Synopsis

Converts JSON file to HTTP headers format.

## Description

Converts a structured JSON file (with header name-value pairs) to HTTP headers format.

## Signature

```powershell
ConvertTo-HttpHeadersFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output HTTP headers file. If not specified, uses input path with .headers extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertTo-HttpHeadersFromJson -InputPath "headers.json"
    
    Converts headers.json to headers.headers.
``

## Aliases

This function has the following aliases:

- `json-to-headers` - Converts JSON file to HTTP headers format.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-http-headers.ps1
