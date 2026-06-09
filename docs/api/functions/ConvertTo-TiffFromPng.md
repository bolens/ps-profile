# ConvertTo-TiffFromPng

## Synopsis

Converts PNG image to TIFF format.

## Description

Converts a PNG image file to TIFF format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertTo-TiffFromPng
```

## Parameters

### -InputPath

Path to the input PNG file.

### -OutputPath

Path for the output TIFF file. If not specified, uses input path with .tiff extension.

### -Compression

TIFF compression method (default: lzw). Options: none, lzw, zip, jpeg.


## Examples

### Example 1

```powershell
ConvertTo-TiffFromPng -InputPath "image.png" -OutputPath "image.tiff" -Compression zip
```

## Aliases

This function has the following aliases:

- `png-to-tif` - Converts PNG image to TIFF format.
- `png-to-tiff` - Converts PNG image to TIFF format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/tiff.ps1
