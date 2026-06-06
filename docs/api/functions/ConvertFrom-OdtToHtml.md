# ConvertFrom-OdtToHtml

## Synopsis

Converts ODT file to HTML.

## Description

Uses pandoc to convert an ODT file to HTML format.

## Signature

```powershell
ConvertFrom-OdtToHtml
```

## Parameters

### -InputPath

Path to the input ODT file.

### -OutputPath

Path for the output HTML file. If not specified, uses input path with .html extension.


## Examples

### Example 1

`powershell
ConvertFrom-OdtToHtml -InputPath "document.odt" -OutputPath "document.html"
``

## Aliases

This function has the following aliases:

- `odt-to-html` - Converts ODT file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-odt.ps1
