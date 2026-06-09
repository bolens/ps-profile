# ConvertFrom-Fb2ToMarkdown

## Synopsis

Converts FB2 file to Markdown.

## Description

Uses pandoc to convert a FictionBook (FB2) e-book file to Markdown format.

## Signature

```powershell
ConvertFrom-Fb2ToMarkdown
```

## Parameters

### -InputPath

The path to the FB2 file (.fb2 or .fbz extension).

### -OutputPath

The path for the output Markdown file. If not specified, uses input path with .md extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertFrom-Fb2ToMarkdown -InputPath "book.fb2"
```

Converts book.fb2 to book.md.

## Aliases

This function has the following aliases:

- `fb2-to-markdown` - Converts FB2 file to Markdown.


## Source

Defined in: ../profile.d/conversion-modules/document/document-fb2.ps1
