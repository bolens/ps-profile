# ConvertFrom-SvgToJpeg

## Synopsis

Converts SVG image to JPEG format.

## Description

Converts an SVG image file to JPEG format using ImageMagick or GraphicsMagick. SVG is rasterized at the specified dimensions.

## Signature

```powershell
ConvertFrom-SvgToJpeg
```

## Parameters

### -InputPath

Path to the input SVG file.

### -OutputPath

Path for the output JPEG file. If not specified, uses input path with .jpg extension.

### -Width

Output width in pixels (default: 1024).

### -Height

Output height in pixels (default: 1024).

### -Quality

JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

`powershell
ConvertFrom-SvgToJpeg -InputPath "image.svg" -OutputPath "image.jpg" -Width 2048 -Height 2048 -Quality 95
``

## Aliases

This function has the following aliases:

- `svg-to-jpeg` - Converts SVG image to JPEG format.
- `svg-to-jpg` - Converts SVG image to JPEG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/svg.ps1
