# ConvertTo-UrlUriFromJson

## Synopsis

Converts JSON file to URL/URI format.

## Description

Converts a structured JSON file (with URL components) to URL/URI format.

## Signature

```powershell
ConvertTo-UrlUriFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output URL/URI file. If not specified, uses input path with .url extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertTo-UrlUriFromJson -InputPath "url.json"
```

Converts url.json to url.url.

## Aliases

This function has the following aliases:

- `json-to-uri` - Converts JSON file to URL/URI format.
- `json-to-url` - Converts JSON file to URL/URI format.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-url-uri.ps1
