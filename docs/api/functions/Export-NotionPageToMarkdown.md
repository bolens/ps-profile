# Export-NotionPageToMarkdown

## Synopsis

Exports a Notion page to markdown using notion2md or notionify-cli.

## Description

Wraps available Notion export CLIs. Requires NOTION_TOKEN or -Token.

## Signature

```powershell
Export-NotionPageToMarkdown
```

## Parameters

### -Url

Notion page URL or page ID.

### -OutputPath

Output directory or file path for exported markdown.

### -Token

Notion integration token. Defaults to $env:NOTION_TOKEN.

### -DownloadAssets

Download images and attachments when supported by the CLI.


## Outputs

None. Writes files via the underlying CLI.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `notion-to-markdown` - Exports a Notion page to markdown using notion2md or notionify-cli.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown-notes.ps1
