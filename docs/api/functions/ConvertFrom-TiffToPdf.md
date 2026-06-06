# ConvertFrom-TiffToPdf

## Synopsis

Converts TIFF image to PDF format.

## Description

Converts a TIFF image file to PDF format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertFrom-TiffToPdf
```

## Parameters

### -InputPath

Path to the input TIFF file.

### -OutputPath

Path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

`powershell
ConvertFrom-TiffToPdf -InputPath "image.tiff" -OutputPath "image.pdf"
``

## Aliases

This function has the following aliases:

- `tif-to-pdf` - Converts TIFF image to PDF format.
- `tiff-to-pdf` - Converts TIFF image to PDF format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/tiff.ps1
