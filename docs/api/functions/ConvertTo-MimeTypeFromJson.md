# ConvertTo-MimeTypeFromJson

## Synopsis

Converts JSON file to MIME type format.

## Description

Converts a structured JSON file (with MIME type components) to MIME type format.

## Signature

```powershell
ConvertTo-MimeTypeFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output MIME type file. If not specified, uses input path with .mime extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertTo-MimeTypeFromJson -InputPath "mime.json"
```

Converts mime.json to mime.mime.

## Aliases

This function has the following aliases:

- `json-to-mime` - Converts JSON file to MIME type format.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-mime-types.ps1
