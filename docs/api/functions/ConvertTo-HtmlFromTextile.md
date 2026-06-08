# ConvertTo-HtmlFromTextile

## Synopsis

Converts Textile file to HTML.

## Description

Uses pandoc to convert a Textile file to HTML format.

## Signature

```powershell
ConvertTo-HtmlFromTextile
```

## Parameters

### -InputPath

The path to the Textile file (.textile or .tx extension).

### -OutputPath

The path for the output HTML file. If not specified, uses input path with .html extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertTo-HtmlFromTextile -InputPath "document.textile"
```

Converts document.textile to document.html.

## Aliases

This function has the following aliases:

- `textile-to-html` - Converts Textile file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-textile.ps1
