# ConvertFrom-EpubToMarkdown

## Synopsis

Converts EPUB file to Markdown.

## Description

Uses pandoc to convert an EPUB file to Markdown format.

## Signature

```powershell
ConvertFrom-EpubToMarkdown
```

## Parameters

### -InputPath

The path to the EPUB file.

### -OutputPath

The path for the output Markdown file. If not specified, uses input path with .md extension.


## Examples

### Example 1

```powershell
ConvertFrom-EpubToMarkdown -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `epub-to-markdown` - Converts EPUB file to Markdown.


## Source

Defined in: ../profile.d/conversion-modules/document/document-common-epub.ps1
