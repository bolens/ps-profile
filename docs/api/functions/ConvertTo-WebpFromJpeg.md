# ConvertTo-WebpFromJpeg

## Synopsis

Converts JPEG image to WebP format.

## Description

Converts a JPEG image file to WebP format using ImageMagick.

## Signature

```powershell
ConvertTo-WebpFromJpeg
```

## Parameters

### -InputPath

Path to the input JPEG file.

### -OutputPath

Path for the output WebP file. If not specified, uses input path with .webp extension.

### -Quality

WebP quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

```powershell
ConvertTo-WebpFromJpeg -InputPath "image.jpg" -OutputPath "image.webp" -Quality 95
```

## Aliases

This function has the following aliases:

- `jpeg-to-webp` - Converts JPEG image to WebP format.
- `jpg-to-webp` - Converts JPEG image to WebP format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/webp.ps1
