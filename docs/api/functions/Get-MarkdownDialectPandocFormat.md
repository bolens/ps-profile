# Get-MarkdownDialectPandocFormat

## Synopsis

Resolves a markdown dialect alias to a pandoc reader/writer format string.

## Description

Maps friendly dialect names (gfm, obsidian, multimarkdown, etc.) to pandoc format identifiers, including Obsidian-specific extension bundles.

## Signature

```powershell
Get-MarkdownDialectPandocFormat
```

## Parameters

### -Dialect

Dialect alias or pandoc format name.

### -ForOutput

When set, returns the writer-oriented format (e.g. Obsidian export uses gfm+wikilinks).


## Outputs

System.String


## Examples

No examples provided.

## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown-dialects.ps1
