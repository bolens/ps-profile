# ConvertFrom-BmpToPng

## Synopsis

Converts BMP image to PNG format.

## Description

Converts a BMP image file to PNG format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertFrom-BmpToPng
```

## Parameters

### -InputPath

Path to the input BMP file.

### -OutputPath

Path for the output PNG file. If not specified, uses input path with .png extension.


## Examples

### Example 1

`powershell
ConvertFrom-BmpToPng -InputPath "image.bmp" -OutputPath "image.png"
``

## Aliases

This function has the following aliases:

- `bmp-to-png` - Converts BMP image to PNG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/bmp.ps1
