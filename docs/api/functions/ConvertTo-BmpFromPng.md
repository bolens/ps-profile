# ConvertTo-BmpFromPng

## Synopsis

Converts PNG image to BMP format.

## Description

Converts a PNG image file to BMP format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertTo-BmpFromPng
```

## Parameters

### -InputPath

Path to the input PNG file.

### -OutputPath

Path for the output BMP file. If not specified, uses input path with .bmp extension.


## Examples

### Example 1

```powershell
ConvertTo-BmpFromPng -InputPath "image.png" -OutputPath "image.bmp"
```

## Aliases

This function has the following aliases:

- `png-to-bmp` - Converts PNG image to BMP format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/bmp.ps1
