# ConvertFrom-RtfToHtml

## Synopsis

Converts RTF file to HTML.

## Description

Uses pandoc to convert an RTF file to HTML format.

## Signature

```powershell
ConvertFrom-RtfToHtml
```

## Parameters

### -InputPath

Path to the input RTF file.

### -OutputPath

Path for the output HTML file. If not specified, uses input path with .html extension.


## Examples

### Example 1

```powershell
ConvertFrom-RtfToHtml -InputPath "document.rtf" -OutputPath "document.html"
```

## Aliases

This function has the following aliases:

- `rtf-to-html` - Converts RTF file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-rtf.ps1
