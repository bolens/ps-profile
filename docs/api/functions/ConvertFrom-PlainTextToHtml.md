# ConvertFrom-PlainTextToHtml

## Synopsis

Converts Plain Text file to HTML.

## Description

Uses pandoc to convert a Plain Text file to HTML format.

## Signature

```powershell
ConvertFrom-PlainTextToHtml
```

## Parameters

### -InputPath

Path to the input Plain Text file.

### -OutputPath

Path for the output HTML file. If not specified, uses input path with .html extension.

### -Encoding

Text encoding of the input file (default: UTF8).


## Examples

### Example 1

`powershell
ConvertFrom-PlainTextToHtml -InputPath "document.txt" -OutputPath "document.html"
``

## Aliases

This function has the following aliases:

- `text-to-html` - Converts Plain Text file to HTML.
- `txt-to-html` - Converts Plain Text file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-plaintext.ps1
