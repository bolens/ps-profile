# Convert-JoplinExportForObsidian

## Synopsis

Reorganizes a Joplin markdown export for Obsidian vault import.

## Description

Moves attachments from a global _resources folder into per-note _resources directories and cleans trailing underscores from filenames.

## Signature

```powershell
Convert-JoplinExportForObsidian
```

## Parameters

### -ExportDirectory

Root directory of a Joplin "Markdown + Front Matter" export.

### -WhatIf

Preview changes without moving files.


## Outputs

PSCustomObject summary with MovedResources and UpdatedFiles counts.


## Examples

### Example 1

```powershell
Convert-JoplinExportForObsidian -ExportDirectory 'value'
```

## Aliases

This function has the following aliases:

- `joplin-export-to-obsidian` - Reorganizes a Joplin markdown export for Obsidian vault import.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown-notes.ps1
