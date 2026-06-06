# ConvertFrom-IcoToJpeg

## Synopsis

Converts ICO image to JPEG format.

## Description

Converts an ICO image file to JPEG format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertFrom-IcoToJpeg
```

## Parameters

### -InputPath

Path to the input ICO file.

### -OutputPath

Path for the output JPEG file. If not specified, uses input path with .jpg extension.

### -Quality

JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.


## Examples

### Example 1

`powershell
ConvertFrom-IcoToJpeg -InputPath "icon.ico" -OutputPath "icon.jpg" -Quality 95
``

## Aliases

This function has the following aliases:

- `ico-to-jpeg` - Converts ICO image to JPEG format.
- `ico-to-jpg` - Converts ICO image to JPEG format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/ico.ps1
