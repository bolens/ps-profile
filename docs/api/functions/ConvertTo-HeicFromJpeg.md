# ConvertTo-HeicFromJpeg

## Synopsis

Converts JPEG image to HEIC format.

## Description

Converts a JPEG image file to HEIC format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertTo-HeicFromJpeg
```

## Parameters

### -InputPath

Path to the input JPEG file.

### -OutputPath

Path for the output HEIC file. If not specified, uses input path with .heic extension.

### -Quality

HEIC quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

`powershell
ConvertTo-HeicFromJpeg -InputPath "image.jpg" -OutputPath "image.heic" -Quality 95
``

## Aliases

This function has the following aliases:

- `jpeg-to-heic` - Converts JPEG image to HEIC format.
- `jpeg-to-heif` - Converts JPEG image to HEIC format.
- `jpg-to-heic` - Converts JPEG image to HEIC format.
- `jpg-to-heif` - Converts JPEG image to HEIC format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/heic.ps1
