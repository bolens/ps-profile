# ConvertFrom-BmpToJpeg

## Synopsis

Converts BMP image to JPEG format.

## Description

Converts a BMP image file to JPEG format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertFrom-BmpToJpeg
```

## Parameters

### -InputPath

Path to the input BMP file.

### -OutputPath

Path for the output JPEG file. If not specified, uses input path with .jpg extension.

### -Quality

JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

`powershell
ConvertFrom-BmpToJpeg -InputPath "image.bmp" -OutputPath "image.jpg" -Quality 95
``

## Aliases

This function has the following aliases:

- `bmp-to-jpeg` - Converts BMP image to JPEG format.
- `bmp-to-jpg` - Converts BMP image to JPEG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/bmp.ps1
