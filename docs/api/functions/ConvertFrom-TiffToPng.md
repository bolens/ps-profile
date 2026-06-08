# ConvertFrom-TiffToPng

## Synopsis

Converts TIFF image to PNG format.

## Description

Converts a TIFF image file to PNG format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertFrom-TiffToPng
```

## Parameters

### -InputPath

Path to the input TIFF file.

### -OutputPath

Path for the output PNG file. If not specified, uses input path with .png extension.


## Examples

### Example 1

```powershell
ConvertFrom-TiffToPng -InputPath "image.tiff" -OutputPath "image.png"
```

## Aliases

This function has the following aliases:

- `tif-to-png` - Converts TIFF image to PNG format.
- `tiff-to-png` - Converts TIFF image to PNG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/tiff.ps1
