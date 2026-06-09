# ConvertTo-IcoFromJpeg

## Synopsis

Converts JPEG image to ICO format.

## Description

Converts a JPEG image file to ICO format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertTo-IcoFromJpeg
```

## Parameters

### -InputPath

Path to the input JPEG file.

### -OutputPath

Path for the output ICO file. If not specified, uses input path with .ico extension.


## Examples

### Example 1

```powershell
ConvertTo-IcoFromJpeg -InputPath "icon.jpg" -OutputPath "icon.ico"
```

## Aliases

This function has the following aliases:

- `jpeg-to-ico` - Converts JPEG image to ICO format.
- `jpg-to-ico` - Converts JPEG image to ICO format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/ico.ps1
