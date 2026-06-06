# ConvertFrom-AvifToJpeg

## Synopsis

Converts AVIF image to JPEG format.

## Description

Converts an AVIF image file to JPEG format using ImageMagick.

## Signature

```powershell
ConvertFrom-AvifToJpeg
```

## Parameters

### -InputPath

Path to the input AVIF file.

### -OutputPath

Path for the output JPEG file. If not specified, uses input path with .jpg extension.

### -Quality

JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

`powershell
ConvertFrom-AvifToJpeg -InputPath "image.avif" -OutputPath "image.jpg" -Quality 95
``

## Aliases

This function has the following aliases:

- `avif-to-jpeg` - Converts AVIF image to JPEG format.
- `avif-to-jpg` - Converts AVIF image to JPEG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/avif.ps1
