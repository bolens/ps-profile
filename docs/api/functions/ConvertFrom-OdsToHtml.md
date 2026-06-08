# ConvertFrom-OdsToHtml

## Synopsis

Converts ODS file to HTML.

## Description

Uses pandoc to convert an ODS file to HTML format.

## Signature

```powershell
ConvertFrom-OdsToHtml
```

## Parameters

### -InputPath

Path to the input ODS file.

### -OutputPath

Path for the output HTML file. If not specified, uses input path with .html extension.


## Examples

### Example 1

```powershell
ConvertFrom-OdsToHtml -InputPath "spreadsheet.ods" -OutputPath "spreadsheet.html"
```

## Aliases

This function has the following aliases:

- `ods-to-html` - Converts ODS file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-ods.ps1
