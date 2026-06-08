# ConvertTo-QrCodeFromJson

## Synopsis

Converts JSON file to QR Code image.

## Description

Reads JSON from a file and generates a QR code image containing the JSON data. Requires Node.js and qrcode package.

## Signature

```powershell
ConvertTo-QrCodeFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output QR code image file. If not specified, uses input path with .png extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertTo-QrCodeFromJson -InputPath "data.json"
```

Converts data.json to data.png QR code.

## Aliases

This function has the following aliases:

- `json-to-qrcode` - Converts JSON file to QR Code image.


## Source

Defined in: ../profile.d/conversion-modules/specialized/specialized-qrcode.ps1
