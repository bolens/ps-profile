# ConvertTo-BmpFromJpeg

## Synopsis

Converts JPEG image to BMP format.

## Description

Converts a JPEG image file to BMP format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertTo-BmpFromJpeg
```

## Parameters

### -InputPath

Path to the input JPEG file.

### -OutputPath

Path for the output BMP file. If not specified, uses input path with .bmp extension.


## Examples

### Example 1

```powershell
ConvertTo-BmpFromJpeg -InputPath "image.jpg" -OutputPath "image.bmp"
```

## Aliases

This function has the following aliases:

- `jpeg-to-bmp` - Converts JPEG image to BMP format.
- `jpg-to-bmp` - Converts JPEG image to BMP format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/bmp.ps1
