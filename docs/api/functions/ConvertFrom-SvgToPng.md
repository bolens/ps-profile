# ConvertFrom-SvgToPng

## Synopsis

Converts SVG image to PNG format.

## Description

Converts an SVG image file to PNG format using ImageMagick or GraphicsMagick. SVG is rasterized at the specified dimensions.

## Signature

```powershell
ConvertFrom-SvgToPng
```

## Parameters

### -InputPath

Path to the input SVG file.

### -OutputPath

Path for the output PNG file. If not specified, uses input path with .png extension.

### -Width

Output width in pixels (default: 1024).

### -Height

Output height in pixels (default: 1024).


## Examples

### Example 1

`powershell
ConvertFrom-SvgToPng -InputPath "image.svg" -OutputPath "image.png" -Width 2048 -Height 2048
``

## Aliases

This function has the following aliases:

- `svg-to-png` - Converts SVG image to PNG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/svg.ps1
