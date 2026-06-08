# Invoke-MarkdownDialectConversion

## Synopsis

Converts markdown between dialects using pandoc.

## Description

Internal dispatcher used by Convert-MarkdownDialect aliases. Loads document conversion helpers when needed and forwards to _Convert-MarkdownDialect.

## Signature

```powershell
Invoke-MarkdownDialectConversion
```

## Parameters

### -InputPath

Path to the input markdown file.

### -OutputPath

Optional output path. Defaults to the input path with .md extension.

### -From

Source dialect alias or pandoc reader format.

### -To

Target dialect alias or pandoc writer format.


## Examples

### Example 1

`powershell
Invoke-MarkdownDialectConversion -InputPath note.md -From obsidian -To gfm
``

## Aliases

This function has the following aliases:

- `convert-markdown-dialect` - Converts markdown between dialects using pandoc.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown-dialects.ps1
