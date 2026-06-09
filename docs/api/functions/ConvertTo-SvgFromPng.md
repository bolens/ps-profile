# ConvertTo-SvgFromPng

## Synopsis

Converts PNG image to SVG format.

## Description

Converts a PNG image file to SVG format using ImageMagick or GraphicsMagick. Note: This creates a raster image embedded in SVG, not a true vector conversion.

## Signature

```powershell
ConvertTo-SvgFromPng
```

## Parameters

### -InputPath

Path to the input PNG file.

### -OutputPath

Path for the output SVG file. If not specified, uses input path with .svg extension.


## Examples

### Example 1

```powershell
ConvertTo-SvgFromPng -InputPath "image.png" -OutputPath "image.svg"
```

## Aliases

This function has the following aliases:

- `png-to-svg` - Converts PNG image to SVG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/svg.ps1
