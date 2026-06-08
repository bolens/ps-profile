# ConvertTo-MobiFromEpub

## Synopsis

Converts EPUB file to MOBI/AZW.

## Description

Uses Calibre or pandoc to convert an EPUB file to MOBI/AZW format.

## Signature

```powershell
ConvertTo-MobiFromEpub
```

## Parameters

### -InputPath

Path to the input EPUB file.

### -OutputPath

Path for the output MOBI/AZW file. If not specified, uses input path with appropriate extension.

### -Format

Output format: 'mobi', 'azw', or 'azw3' (default: 'mobi').


## Examples

### Example 1

```powershell
ConvertTo-MobiFromEpub -InputPath "book.epub" -OutputPath "book.mobi" -Format mobi
```

## Aliases

This function has the following aliases:

- `epub-to-azw` - Converts EPUB file to MOBI/AZW.
- `epub-to-azw3` - Converts EPUB file to MOBI/AZW.
- `epub-to-mobi` - Converts EPUB file to MOBI/AZW.


## Source

Defined in: ../profile.d/conversion-modules/document/document-ebook-mobi.ps1
