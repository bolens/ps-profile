# ConvertTo-MarkdownLinksFromWikilinks

## Synopsis

Converts Obsidian wikilinks to standard markdown links.

## Description

Transforms [[page]], [[page|alias]], and [[page#anchor|alias]] into markdown links.

## Signature

```powershell
ConvertTo-MarkdownLinksFromWikilinks
```

## Parameters

### -Content

Markdown content to transform.

### -InputPath

Path to a markdown file to read.

### -OutputPath

Optional path to write transformed content.


## Outputs

System.String when content is piped or -PassThru is used.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `wikilinks-to-md-links` - Converts Obsidian wikilinks to standard markdown links.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown-notes.ps1
