# ConvertFrom-BarcodeToText

## Synopsis

Converts Barcode image to text.

## Description

Decodes a barcode image and extracts the text data. Note: Full decoding requires additional image processing libraries (barcode-reader, zbar, etc.).

## Signature

```powershell
ConvertFrom-BarcodeToText
```

## Parameters

### -InputPath

The path to the barcode image file (.png, .jpg, .jpeg, .gif, .bmp).

### -OutputPath

The path for the output text file. If not specified, uses input path with .txt extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertFrom-BarcodeToText -InputPath "barcode.png"
```

Decodes barcode.png to barcode.txt.

## Notes

Full barcode decoding requires additional libraries. This function currently indicates the requirement. .EXAMPLE ConvertFrom-BarcodeToText -InputPath "barcode.png" Decodes barcode.png to barcode.txt.


## Aliases

This function has the following aliases:

- `barcode-to-text` - Converts Barcode image to text.


## Source

Defined in: ../profile.d/conversion-modules/specialized/specialized-barcode.ps1
