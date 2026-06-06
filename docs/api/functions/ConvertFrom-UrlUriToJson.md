# ConvertFrom-UrlUriToJson

## Synopsis

Converts URL/URI file to JSON format.

## Description

Parses a URL/URI from a file and converts it to structured JSON format with all components.

## Signature

```powershell
ConvertFrom-UrlUriToJson
```

## Parameters

### -InputPath

The path to the file containing the URL/URI (.url or .uri extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertFrom-UrlUriToJson -InputPath "url.url"
    
    Converts url.url to url.json.
``

## Aliases

This function has the following aliases:

- `uri-to-json` - Converts URL/URI file to JSON format.
- `url-to-json` - Converts URL/URI file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-url-uri.ps1
