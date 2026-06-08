# ConvertTo-OrgmodeFromMarkdown

## Synopsis

Converts Markdown file to Org-mode.

## Description

Uses pandoc to convert a Markdown file to Org-mode format.

## Signature

```powershell
ConvertTo-OrgmodeFromMarkdown
```

## Parameters

### -InputPath

Path to the input Markdown file.

### -OutputPath

Path for the output Org-mode file. If not specified, uses input path with .org extension.


## Examples

### Example 1

```powershell
ConvertTo-OrgmodeFromMarkdown -InputPath "document.md" -OutputPath "document.org"
```

## Aliases

This function has the following aliases:

- `markdown-to-org` - Converts Markdown file to Org-mode.
- `markdown-to-orgmode` - Converts Markdown file to Org-mode.
- `md-to-org` - Converts Markdown file to Org-mode.
- `md-to-orgmode` - Converts Markdown file to Org-mode.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-orgmode.ps1
