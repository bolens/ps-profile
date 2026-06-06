# ConvertTo-WebpFromGif

## Synopsis

Converts GIF image to WebP format.

## Description

Converts a GIF image file to WebP format using ImageMagick.

## Signature

```powershell
ConvertTo-WebpFromGif
```

## Parameters

### -InputPath

Path to the input GIF file.

### -OutputPath

Path for the output WebP file. If not specified, uses input path with .webp extension.

### -Quality

WebP quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

`powershell
ConvertTo-WebpFromGif -InputPath "image.gif" -OutputPath "image.webp" -Quality 95
``

## Aliases

This function has the following aliases:

- `gif-to-webp` - Converts GIF image to WebP format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/webp.ps1
