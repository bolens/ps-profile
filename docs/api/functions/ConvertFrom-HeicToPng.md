# ConvertFrom-HeicToPng

## Synopsis

Converts HEIC/HEIF image to PNG format.

## Description

Converts a HEIC/HEIF image file to PNG format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertFrom-HeicToPng
```

## Parameters

### -InputPath

Path to the input HEIC/HEIF file.

### -OutputPath

Path for the output PNG file. If not specified, uses input path with .png extension.


## Examples

### Example 1

```powershell
ConvertFrom-HeicToPng -InputPath "image.heic" -OutputPath "image.png"
```

## Aliases

This function has the following aliases:

- `heic-to-png` - Converts HEIC/HEIF image to PNG format.
- `heif-to-png` - Converts HEIC/HEIF image to PNG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/heic.ps1
