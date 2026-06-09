# ConvertTo-IcoFromPng

## Synopsis

Converts PNG image to ICO format.

## Description

Converts a PNG image file to ICO format using ImageMagick or GraphicsMagick.

## Signature

```powershell
ConvertTo-IcoFromPng
```

## Parameters

### -InputPath

Path to the input PNG file.

### -OutputPath

Path for the output ICO file. If not specified, uses input path with .ico extension.


## Examples

### Example 1

```powershell
ConvertTo-IcoFromPng -InputPath "icon.png" -OutputPath "icon.ico"
```

## Aliases

This function has the following aliases:

- `png-to-ico` - Converts PNG image to ICO format.


## Source

Defined in: ../profile.d/conversion-modules/media/images/ico.ps1
