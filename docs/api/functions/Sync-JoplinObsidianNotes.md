# Sync-JoplinObsidianNotes

## Synopsis

Synchronizes notes between Joplin and Obsidian using joplin-obsidian-bridge.

## Description

Wraps the job CLI from joplin-obsidian-bridge. Use -Preview to dry-run sync.

## Signature

```powershell
Sync-JoplinObsidianNotes
```

## Parameters

### -Force

Execute sync (without this flag, job performs a preview/dry-run).

### -JoplinToObsidian

Sync only from Joplin to Obsidian.

### -ObsidianToJoplin

Sync only from Obsidian to Joplin.

### -Manual

Use interactive confirmation mode (sync-manual).

### -Arguments

Additional arguments forwarded to job.


## Outputs

CLI output from job.


## Examples

### Example 1

```powershell
Sync-JoplinObsidianNotes
```

## Aliases

This function has the following aliases:

- `joplin-obsidian-sync` - Synchronizes notes between Joplin and Obsidian using joplin-obsidian-bridge.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown-notes.ps1
