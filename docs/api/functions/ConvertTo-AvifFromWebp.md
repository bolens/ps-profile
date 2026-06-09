# ConvertTo-AvifFromWebp

## Synopsis

Converts WebP image to AVIF format.

## Description

Converts a WebP image file to AVIF format using ImageMagick.

## Signature

```powershell
ConvertTo-AvifFromWebp
```

## Parameters

### -InputPath

Path to the input WebP file.

### -OutputPath

Path for the output AVIF file. If not specified, uses input path with .avif extension.

### -Quality

AVIF quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

```powershell
ConvertTo-AvifFromWebp -InputPath "image.webp" -OutputPath "image.avif" -Quality 95
```

## Aliases

This function has the following aliases:

- `webp-to-avif` - Converts WebP image to AVIF format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/avif.ps1
