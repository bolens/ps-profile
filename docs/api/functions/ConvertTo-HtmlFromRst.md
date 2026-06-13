# ConvertTo-HtmlFromRst

## Synopsis

Converts RST file to HTML.

## Description

Uses pandoc to convert a reStructuredText (RST) file to HTML format.

## Signature

```powershell
ConvertTo-HtmlFromRst
```

## Parameters

### -InputPath

The path to the RST file.

### -OutputPath

The path for the output HTML file. If not specified, uses input path with .html extension.


## Examples

### Example 1

```powershell
ConvertTo-HtmlFromRst -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `rst-to-html` - Converts RST file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-rst.ps1
