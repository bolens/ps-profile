# ConvertTo-BarcodeFromText

## Synopsis

Converts text file to Barcode image.

## Description

Reads text from a file and generates a barcode image containing that text. Requires Node.js, jsbarcode, and canvas packages.

## Signature

```powershell
ConvertTo-BarcodeFromText
```

## Parameters

### -InputPath

The path to the text file (.txt or .text extension).

### -OutputPath

The path for the output barcode image file. If not specified, uses input path with .png extension.

### -Format

The barcode format to use. Valid values: CODE128, CODE39, EAN13, EAN8, UPC, ITF14, MSI, pharmacode, codabar. Default is CODE128.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertTo-BarcodeFromText -InputPath "data.txt" -Format CODE128
```

Converts data.txt to data.png barcode.

## Aliases

This function has the following aliases:

- `text-to-barcode` - Converts text file to Barcode image.


## Source

Defined in: ../profile.d/conversion-modules/specialized/specialized-barcode.ps1
