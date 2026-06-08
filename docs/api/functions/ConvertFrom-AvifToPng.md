# ConvertFrom-AvifToPng

## Synopsis

Converts AVIF image to PNG format.

## Description

Converts an AVIF image file to PNG format using ImageMagick.

## Signature

```powershell
ConvertFrom-AvifToPng
```

## Parameters

### -InputPath

Path to the input AVIF file.

### -OutputPath

Path for the output PNG file. If not specified, uses input path with .png extension.


## Examples

### Example 1

```powershell
ConvertFrom-AvifToPng -InputPath "image.avif" -OutputPath "image.png"
```

## Aliases

This function has the following aliases:

- `avif-to-png` - Converts AVIF image to PNG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/avif.ps1
