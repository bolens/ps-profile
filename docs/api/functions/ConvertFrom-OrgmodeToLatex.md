# ConvertFrom-OrgmodeToLatex

## Synopsis

Converts Org-mode file to LaTeX.

## Description

Uses pandoc to convert an Org-mode file to LaTeX format.

## Signature

```powershell
ConvertFrom-OrgmodeToLatex
```

## Parameters

### -InputPath

Path to the input Org-mode file.

### -OutputPath

Path for the output LaTeX file. If not specified, uses input path with .tex extension.


## Examples

### Example 1

`powershell
ConvertFrom-OrgmodeToLatex -InputPath "document.org" -OutputPath "document.tex"
``

## Aliases

This function has the following aliases:

- `org-to-latex` - Converts Org-mode file to LaTeX.
- `orgmode-to-latex` - Converts Org-mode file to LaTeX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-orgmode.ps1
