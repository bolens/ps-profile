# Convert-NotionCalloutsToObsidian

## Synopsis

Converts Notion-style callout blockquotes to Obsidian callout syntax.

## Description

Rewrites blockquotes such as "> **Note**" or "> 💡 Tip" into Obsidian callouts like "> [!NOTE]" and "> [!TIP]".

## Signature

```powershell
Convert-NotionCalloutsToObsidian
```

## Parameters

### -Content

Markdown content to transform.

### -InputPath

Path to a markdown file to read.

### -OutputPath

Optional path to write transformed content.


## Outputs

System.String when content is piped or -PassThru is used. .EXAMPLE Convert-NotionCalloutsToObsidian


## Examples

### Example 1

`powershell
Convert-NotionCalloutsToObsidian
``

## Aliases

This function has the following aliases:

- `notion-callouts-to-obsidian` - Converts Notion-style callout blockquotes to Obsidian callout syntax.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown-notes.ps1
