# ConvertTo-TiffFromPdf

## Synopsis

Converts PDF to TIFF format.

## Description

Converts a PDF file to TIFF format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertTo-TiffFromPdf
```

## Parameters

### -InputPath

Path to the input PDF file.

### -OutputPath

Path for the output TIFF file. If not specified, uses input path with .tiff extension.

### -Compression

TIFF compression method (default: lzw). Options: none, lzw, zip, jpeg.


## Examples

### Example 1

```powershell
ConvertTo-TiffFromPdf -InputPath "document.pdf" -OutputPath "document.tiff" -Compression zip
```

## Aliases

This function has the following aliases:

- `pdf-to-tif` - Converts PDF to TIFF format.
- `pdf-to-tiff` - Converts PDF to TIFF format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/tiff.ps1
