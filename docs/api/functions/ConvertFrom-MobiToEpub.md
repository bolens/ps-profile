# ConvertFrom-MobiToEpub

## Synopsis

Converts MOBI/AZW file to EPUB.

## Description

Uses Calibre or pandoc to convert a MOBI/AZW file to EPUB format.

## Signature

```powershell
ConvertFrom-MobiToEpub
```

## Parameters

### -InputPath

Path to the input MOBI/AZW file.

### -OutputPath

Path for the output EPUB file. If not specified, uses input path with .epub extension.


## Examples

### Example 1

`powershell
ConvertFrom-MobiToEpub -InputPath "book.mobi" -OutputPath "book.epub"
``

## Aliases

This function has the following aliases:

- `azw-to-epub` - Converts MOBI/AZW file to EPUB.
- `azw3-to-epub` - Converts MOBI/AZW file to EPUB.
- `mobi-to-epub` - Converts MOBI/AZW file to EPUB.


## Source

Defined in: ../profile.d/conversion-modules/document/document-ebook-mobi.ps1
