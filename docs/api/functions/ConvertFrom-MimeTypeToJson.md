# ConvertFrom-MimeTypeToJson

## Synopsis

Converts MIME type file to JSON format.

## Description

Parses a MIME type from a file and converts it to structured JSON format.

## Signature

```powershell
ConvertFrom-MimeTypeToJson
```

## Parameters

### -InputPath

The path to the file containing the MIME type (.mime or .mimetype extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertFrom-MimeTypeToJson -InputPath "mime.mime"
```

Converts mime.mime to mime.json.

## Aliases

This function has the following aliases:

- `mime-to-json` - Converts MIME type file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-mime-types.ps1
