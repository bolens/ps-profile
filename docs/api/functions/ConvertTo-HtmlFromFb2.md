# ConvertTo-HtmlFromFb2

## Synopsis

Converts FB2 file to HTML.

## Description

Uses pandoc to convert a FictionBook (FB2) e-book file to HTML format.

## Signature

```powershell
ConvertTo-HtmlFromFb2
```

## Parameters

### -InputPath

The path to the FB2 file (.fb2 or .fbz extension).

### -OutputPath

The path for the output HTML file. If not specified, uses input path with .html extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertTo-HtmlFromFb2 -InputPath "book.fb2"
    
    Converts book.fb2 to book.html.
``

## Aliases

This function has the following aliases:

- `fb2-to-html` - Converts FB2 file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-fb2.ps1
