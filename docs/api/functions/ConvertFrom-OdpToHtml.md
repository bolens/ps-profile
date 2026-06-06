# ConvertFrom-OdpToHtml

## Synopsis

Converts ODP file to HTML.

## Description

Uses pandoc to convert an ODP (OpenDocument Presentation) file to HTML format.

## Signature

```powershell
ConvertFrom-OdpToHtml
```

## Parameters

### -InputPath

Path to the input ODP file.

### -OutputPath

Path for the output HTML file. If not specified, uses input path with .html extension.


## Examples

### Example 1

`powershell
ConvertFrom-OdpToHtml -InputPath "presentation.odp" -OutputPath "presentation.html"
``

## Aliases

This function has the following aliases:

- `odp-to-html` - Converts ODP file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-odp.ps1
