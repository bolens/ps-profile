# ConvertTo-WikilinksFromMarkdownLinks

## Synopsis

Converts markdown link syntax to Obsidian wikilinks.

## Description

Transforms markdown links with relative .md paths into Obsidian wikilinks such as [[page|text]] or [[page#anchor|text]]. Skips absolute URLs and non-markdown targets.

## Signature

```powershell
ConvertTo-WikilinksFromMarkdownLinks
```

## Parameters

### -Content

Markdown content to transform.

### -InputPath

Path to a markdown file to read.

### -OutputPath

Optional path to write transformed content.


## Outputs

System.String when -PassThru is specified or content is piped.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `md-links-to-wikilinks` - Converts markdown link syntax to Obsidian wikilinks.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown-notes.ps1
