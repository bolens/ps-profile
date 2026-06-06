# ConvertFrom-TiffToJpeg

## Synopsis

Converts TIFF image to JPEG format.

## Description

Converts a TIFF image file to JPEG format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertFrom-TiffToJpeg
```

## Parameters

### -InputPath

Path to the input TIFF file.

### -OutputPath

Path for the output JPEG file. If not specified, uses input path with .jpg extension.

### -Quality

JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

`powershell
ConvertFrom-TiffToJpeg -InputPath "image.tiff" -OutputPath "image.jpg" -Quality 95
``

## Aliases

This function has the following aliases:

- `tif-to-jpeg` - Converts TIFF image to JPEG format.
- `tif-to-jpg` - Converts TIFF image to JPEG format.
- `tiff-to-jpeg` - Converts TIFF image to JPEG format.
- `tiff-to-jpg` - Converts TIFF image to JPEG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/tiff.ps1
