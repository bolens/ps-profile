# ConvertTo-MediawikiFromMarkdown

## Synopsis

Converts markdown between dialects/standards using pandoc.

## Description

Converts a markdown file from one dialect to another. Supports CommonMark, GFM, Pandoc markdown, MultiMarkdown, PHP Markdown Extra, strict markdown, and Obsidian-flavored markdown (wikilinks, highlights, task lists).

## Signature

```powershell
ConvertTo-MediawikiFromMarkdown
```

## Parameters

### -InputPath

Path to the input markdown file.

### -OutputPath

Optional output path. Defaults to the input path with .md extension.

### -From

Source dialect (commonmark, gfm, obsidian, multimarkdown, phpextra, strict, markdown).

### -To

Target dialect.


## Examples

### Example 1

```powershell
Convert-MarkdownDialect -InputPath note.md -From obsidian -To gfm
```

## Aliases

This function has the following aliases:

- `markdown-to-mediawiki` - Converts markdown between dialects/standards using pandoc.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown-dialects.ps1
