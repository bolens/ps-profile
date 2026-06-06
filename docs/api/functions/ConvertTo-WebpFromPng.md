# ConvertTo-WebpFromPng

## Synopsis

Converts PNG image to WebP format.

## Description

Converts a PNG image file to WebP format using ImageMagick.

## Signature

```powershell
ConvertTo-WebpFromPng
```

## Parameters

### -InputPath

Path to the input PNG file.

### -OutputPath

Path for the output WebP file. If not specified, uses input path with .webp extension.

### -Quality

WebP quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

`powershell
ConvertTo-WebpFromPng -InputPath "image.png" -OutputPath "image.webp" -Quality 95
``

## Aliases

This function has the following aliases:

- `png-to-webp` - Converts PNG image to WebP format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/webp.ps1
