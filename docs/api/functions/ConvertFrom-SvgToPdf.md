# ConvertFrom-SvgToPdf

## Synopsis

Converts SVG image to PDF format.

## Description

Converts an SVG image file to PDF format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertFrom-SvgToPdf
```

## Parameters

### -InputPath

Path to the input SVG file.

### -OutputPath

Path for the output PDF file. If not specified, uses input path with .pdf extension.


## Examples

### Example 1

`powershell
ConvertFrom-SvgToPdf -InputPath "image.svg" -OutputPath "image.pdf"
``

## Aliases

This function has the following aliases:

- `svg-to-pdf` - Converts SVG image to PDF format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/svg.ps1
