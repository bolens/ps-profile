# ConvertFrom-OrgmodeToMarkdown

## Synopsis

Converts Org-mode file to Markdown.

## Description

Uses pandoc to convert an Org-mode file to Markdown format.

## Signature

```powershell
ConvertFrom-OrgmodeToMarkdown
```

## Parameters

### -InputPath

Path to the input Org-mode file.

### -OutputPath

Path for the output Markdown file. If not specified, uses input path with .md extension.


## Examples

### Example 1

```powershell
ConvertFrom-OrgmodeToMarkdown -InputPath "document.org" -OutputPath "document.md"
```

## Aliases

This function has the following aliases:

- `org-to-markdown` - Converts Org-mode file to Markdown.
- `orgmode-to-markdown` - Converts Org-mode file to Markdown.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-orgmode.ps1
