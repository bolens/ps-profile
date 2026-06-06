# ConvertFrom-OrgmodeToHtml

## Synopsis

Converts Org-mode file to HTML.

## Description

Uses pandoc to convert an Org-mode file to HTML format.

## Signature

```powershell
ConvertFrom-OrgmodeToHtml
```

## Parameters

### -InputPath

Path to the input Org-mode file.

### -OutputPath

Path for the output HTML file. If not specified, uses input path with .html extension.


## Examples

### Example 1

`powershell
ConvertFrom-OrgmodeToHtml -InputPath "document.org" -OutputPath "document.html"
``

## Aliases

This function has the following aliases:

- `org-to-html` - Converts Org-mode file to HTML.
- `orgmode-to-html` - Converts Org-mode file to HTML.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-orgmode.ps1
