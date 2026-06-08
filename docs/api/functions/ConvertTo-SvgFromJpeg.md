# ConvertTo-SvgFromJpeg

## Synopsis

Converts JPEG image to SVG format.

## Description

Converts a JPEG image file to SVG format using ImageMagick or GraphicsMagick. Note: This creates a raster image embedded in SVG, not a true vector conversion.

## Signature

```powershell
ConvertTo-SvgFromJpeg
```

## Parameters

### -InputPath

Path to the input JPEG file.

### -OutputPath

Path for the output SVG file. If not specified, uses input path with .svg extension.


## Examples

### Example 1

```powershell
ConvertTo-SvgFromJpeg -InputPath "image.jpg" -OutputPath "image.svg"
```

## Aliases

This function has the following aliases:

- `jpeg-to-svg` - Converts JPEG image to SVG format.
- `jpg-to-svg` - Converts JPEG image to SVG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/svg.ps1
