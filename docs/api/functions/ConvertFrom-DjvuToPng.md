# ConvertFrom-DjvuToPng

## Synopsis

Converts DjVu file to PNG.

## Description

Converts a DjVu document file to PNG image format using ImageMagick or djvulibre tools.

## Signature

```powershell
ConvertFrom-DjvuToPng
```

## Parameters

### -InputPath

The path to the DjVu file (.djvu or .djv extension).

### -OutputPath

The path for the output PNG file. If not specified, uses input path with .png extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertFrom-DjvuToPng -InputPath "document.djvu"
```

Converts document.djvu to document.png.

## Aliases

This function has the following aliases:

- `djvu-to-png` - Converts DjVu file to PNG.


## Source

Defined in: ../profile.d/conversion-modules/document/document-djvu.ps1
