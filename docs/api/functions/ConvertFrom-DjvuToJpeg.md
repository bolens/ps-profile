# ConvertFrom-DjvuToJpeg

## Synopsis

Converts DjVu file to JPEG.

## Description

Converts a DjVu document file to JPEG image format using ImageMagick or djvulibre tools.

## Signature

```powershell
ConvertFrom-DjvuToJpeg
```

## Parameters

### -InputPath

The path to the DjVu file (.djvu or .djv extension).

### -OutputPath

The path for the output JPEG file. If not specified, uses input path with .jpg extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertFrom-DjvuToJpeg -InputPath "document.djvu"
    
    Converts document.djvu to document.jpg.
``

## Aliases

This function has the following aliases:

- `djvu-to-jpeg` - Converts DjVu file to JPEG.
- `djvu-to-jpg` - Converts DjVu file to JPEG.


## Source

Defined in: ../profile.d/conversion-modules/document/document-djvu.ps1
