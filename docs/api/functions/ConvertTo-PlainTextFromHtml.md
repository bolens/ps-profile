# ConvertTo-PlainTextFromHtml

## Synopsis

Converts HTML file to Plain Text.

## Description

Uses pandoc to convert an HTML file to Plain Text format.

## Signature

```powershell
ConvertTo-PlainTextFromHtml
```

## Parameters

### -InputPath

Path to the input HTML file.

### -OutputPath

Path for the output Plain Text file. If not specified, uses input path with .txt extension.

### -Encoding

Text encoding for the output file (default: UTF8).


## Examples

### Example 1

```powershell
ConvertTo-PlainTextFromHtml -InputPath "document.html" -OutputPath "document.txt" -Encoding UTF8
```

## Aliases

This function has the following aliases:

- `html-to-text` - Converts HTML file to Plain Text.
- `html-to-txt` - Converts HTML file to Plain Text.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-plaintext.ps1
