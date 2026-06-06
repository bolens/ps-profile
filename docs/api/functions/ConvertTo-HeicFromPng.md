# ConvertTo-HeicFromPng

## Synopsis

Converts PNG image to HEIC format.

## Description

Converts a PNG image file to HEIC format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertTo-HeicFromPng
```

## Parameters

### -InputPath

Path to the input PNG file.

### -OutputPath

Path for the output HEIC file. If not specified, uses input path with .heic extension.

### -Quality

HEIC quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

`powershell
ConvertTo-HeicFromPng -InputPath "image.png" -OutputPath "image.heic" -Quality 95
``

## Aliases

This function has the following aliases:

- `png-to-heic` - Converts PNG image to HEIC format.
- `png-to-heif` - Converts PNG image to HEIC format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/heic.ps1
