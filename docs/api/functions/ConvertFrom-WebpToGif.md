# ConvertFrom-WebpToGif

## Synopsis

Converts WebP image to GIF format.

## Description

Converts a WebP image file to GIF format using ImageMagick.

## Signature

```powershell
ConvertFrom-WebpToGif
```

## Parameters

### -InputPath

Path to the input WebP file.

### -OutputPath

Path for the output GIF file. If not specified, uses input path with .gif extension.


## Examples

### Example 1

`powershell
ConvertFrom-WebpToGif -InputPath "image.webp" -OutputPath "image.gif"
``

## Aliases

This function has the following aliases:

- `webp-to-gif` - Converts WebP image to GIF format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/webp.ps1
