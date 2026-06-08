# ConvertFrom-EpubToHtml

## Synopsis

Converts EPUB file to HTML.

## Description

Uses pandoc to convert an EPUB file to HTML format.

## Signature

```powershell
ConvertFrom-EpubToHtml
```

## Parameters

### -InputPath

The path to the EPUB file.

### -OutputPath

The path for the output HTML file. If not specified, uses input path with .html extension.


## Examples

### Example 1

`powershell
ConvertFrom-EpubToHtml -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `epub-to-html` - Converts EPUB file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-common-epub.ps1
