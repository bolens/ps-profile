# ConvertFrom-TextileToMarkdown

## Synopsis

Converts Textile file to Markdown.

## Description

Uses pandoc to convert a Textile file to Markdown format.

## Signature

```powershell
ConvertFrom-TextileToMarkdown
```

## Parameters

### -InputPath

The path to the Textile file (.textile or .tx extension).

### -OutputPath

The path for the output Markdown file. If not specified, uses input path with .md extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertFrom-TextileToMarkdown -InputPath "document.textile"
    
    Converts document.textile to document.md.
``

## Aliases

This function has the following aliases:

- `textile-to-markdown` - Converts Textile file to Markdown.


## Source

Defined in: ../profile.d/conversion-modules/document/document-textile.ps1
