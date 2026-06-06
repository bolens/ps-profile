# ConvertFrom-EpubToDocx

## Synopsis

Converts EPUB file to DOCX.

## Description

Uses pandoc to convert an EPUB file to Microsoft Word DOCX format.

## Signature

```powershell
ConvertFrom-EpubToDocx
```

## Parameters

### -InputPath

The path to the EPUB file.

### -OutputPath

The path for the output DOCX file. If not specified, uses input path with .docx extension.


## Examples

### Example 1

`powershell
ConvertFrom-EpubToDocx -InputPath "book.epub" -OutputPath "book.docx"
``

## Aliases

This function has the following aliases:

- `epub-to-docx` - Converts EPUB file to DOCX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-common-epub.ps1
