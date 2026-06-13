# ConvertFrom-AvifToWebp

## Synopsis

Converts AVIF image to WebP format.

## Description

Converts an AVIF image file to WebP format using ImageMagick.

## Signature

```powershell
ConvertFrom-AvifToWebp
```

## Parameters

### -InputPath

Path to the input AVIF file.

### -OutputPath

Path for the output WebP file. If not specified, uses input path with .webp extension.

### -Quality

WebP quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

```powershell
ConvertFrom-AvifToWebp -InputPath "image.avif" -OutputPath "image.webp" -Quality 95
```

## Aliases

This function has the following aliases:

- `avif-to-webp` - Converts AVIF image to WebP format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/avif.ps1
