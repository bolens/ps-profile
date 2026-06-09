# Convert-LogseqPropertiesToYamlFrontMatter

## Synopsis

Converts Logseq property lines to YAML front matter.

## Description

Moves leading key:: value lines (Logseq page properties) into a YAML front matter block at the top of the document.

## Signature

```powershell
Convert-LogseqPropertiesToYamlFrontMatter
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

### Example 1

```powershell
Convert-LogseqPropertiesToYamlFrontMatter -Content 'text' -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `logseq-to-yaml` - Converts Logseq property lines to YAML front matter.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown-notes.ps1
