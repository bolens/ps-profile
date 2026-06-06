# ConvertFrom-WebpToJpeg

## Synopsis

Converts WebP image to JPEG format.

## Description

Converts a WebP image file to JPEG format using ImageMagick.

## Signature

```powershell
ConvertFrom-WebpToJpeg
```

## Parameters

### -InputPath

Path to the input WebP file.

### -OutputPath

Path for the output JPEG file. If not specified, uses input path with .jpg extension.

### -Quality

JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

`powershell
ConvertFrom-WebpToJpeg -InputPath "image.webp" -OutputPath "image.jpg" -Quality 95
``

## Aliases

This function has the following aliases:

- `webp-to-jpeg` - Converts WebP image to JPEG format.
- `webp-to-jpg` - Converts WebP image to JPEG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/webp.ps1
