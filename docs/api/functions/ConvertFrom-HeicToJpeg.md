# ConvertFrom-HeicToJpeg

## Synopsis

Converts HEIC/HEIF image to JPEG format.

## Description

Converts a HEIC/HEIF image file to JPEG format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertFrom-HeicToJpeg
```

## Parameters

### -InputPath

Path to the input HEIC/HEIF file.

### -OutputPath

Path for the output JPEG file. If not specified, uses input path with .jpg extension.

### -Quality

JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

`powershell
ConvertFrom-HeicToJpeg -InputPath "image.heic" -OutputPath "image.jpg" -Quality 95
``

## Aliases

This function has the following aliases:

- `heic-to-jpeg` - Converts HEIC/HEIF image to JPEG format.
- `heic-to-jpg` - Converts HEIC/HEIF image to JPEG format.
- `heif-to-jpeg` - Converts HEIC/HEIF image to JPEG format.
- `heif-to-jpg` - Converts HEIC/HEIF image to JPEG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/heic.ps1
