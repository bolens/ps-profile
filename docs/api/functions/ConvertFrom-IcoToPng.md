# ConvertFrom-IcoToPng

## Synopsis

Converts ICO image to PNG format.

## Description

Converts an ICO image file to PNG format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertFrom-IcoToPng
```

## Parameters

### -InputPath

Path to the input ICO file.

### -OutputPath

Path for the output PNG file. If not specified, uses input path with .png extension.


## Examples

### Example 1

```powershell
ConvertFrom-IcoToPng -InputPath "icon.ico" -OutputPath "icon.png"
```

## Aliases

This function has the following aliases:

- `ico-to-png` - Converts ICO image to PNG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/ico.ps1
