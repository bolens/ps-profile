# ConvertTo-TiffFromJpeg

## Synopsis

Converts JPEG image to TIFF format.

## Description

Converts a JPEG image file to TIFF format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertTo-TiffFromJpeg
```

## Parameters

### -InputPath

Path to the input JPEG file.

### -OutputPath

Path for the output TIFF file. If not specified, uses input path with .tiff extension.

### -Compression

TIFF compression method (default: jpeg). Options: none, lzw, zip, jpeg.


## Examples

### Example 1

```powershell
ConvertTo-TiffFromJpeg -InputPath "image.jpg" -OutputPath "image.tiff" -Compression lzw
```

## Aliases

This function has the following aliases:

- `jpeg-to-tif` - Converts JPEG image to TIFF format.
- `jpeg-to-tiff` - Converts JPEG image to TIFF format.
- `jpg-to-tif` - Converts JPEG image to TIFF format.
- `jpg-to-tiff` - Converts JPEG image to TIFF format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/tiff.ps1
