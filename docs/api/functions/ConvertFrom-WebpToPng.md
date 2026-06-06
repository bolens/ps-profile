# ConvertFrom-WebpToPng

## Synopsis

Converts WebP image to PNG format.

## Description

Converts a WebP image file to PNG format using ImageMagick.

## Signature

```powershell
ConvertFrom-WebpToPng
```

## Parameters

### -InputPath

Path to the input WebP file.

### -OutputPath

Path for the output PNG file. If not specified, uses input path with .png extension.


## Examples

### Example 1

`powershell
ConvertFrom-WebpToPng -InputPath "image.webp" -OutputPath "image.png"
``

## Aliases

This function has the following aliases:

- `webp-to-png` - Converts WebP image to PNG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/webp.ps1
