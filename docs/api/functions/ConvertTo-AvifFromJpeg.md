# ConvertTo-AvifFromJpeg

## Synopsis

Converts JPEG image to AVIF format.

## Description

Converts a JPEG image file to AVIF format using ImageMagick.

## Signature

```powershell
ConvertTo-AvifFromJpeg
```

## Parameters

### -InputPath

Path to the input JPEG file.

### -OutputPath

Path for the output AVIF file. If not specified, uses input path with .avif extension.

### -Quality

AVIF quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

```powershell
ConvertTo-AvifFromJpeg -InputPath "image.jpg" -OutputPath "image.avif" -Quality 95
```

## Aliases

This function has the following aliases:

- `jpeg-to-avif` - Converts JPEG image to AVIF format.
- `jpg-to-avif` - Converts JPEG image to AVIF format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/avif.ps1
