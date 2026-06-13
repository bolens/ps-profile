# ConvertTo-BarcodeFromJson

## Synopsis

Converts JSON file to Barcode image.

## Description

Reads JSON from a file and generates a barcode image containing the JSON data. Requires Node.js, jsbarcode, and canvas packages.

## Signature

```powershell
ConvertTo-BarcodeFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output barcode image file. If not specified, uses input path with .png extension.

### -Format

The barcode format to use. Valid values: CODE128, CODE39, EAN13, EAN8, UPC, ITF14, MSI, pharmacode, codabar. Default is CODE128.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertTo-BarcodeFromJson -InputPath "data.json" -Format CODE128
```

Converts data.json to data.png barcode.

## Aliases

This function has the following aliases:

- `json-to-barcode` - Converts JSON file to Barcode image.


## Source

Defined in: ../profile.d/conversion-modules/specialized/specialized-barcode.ps1
