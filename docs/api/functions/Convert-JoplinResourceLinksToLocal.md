# Convert-JoplinResourceLinksToLocal

## Synopsis

Rewrites Joplin resource links to local attachment paths.

## Description

Converts Joplin-style resource references (![](:/resourceId)) to standard markdown image links using a resource map or a _resources directory lookup.

## Signature

```powershell
Convert-JoplinResourceLinksToLocal
```

## Parameters

### -Content

Markdown content to transform.

### -InputPath

Path to a markdown file to read.

### -OutputPath

Optional path to write transformed content.

### -ResourceMap

Hashtable mapping Joplin resource IDs to relative file paths.

### -ResourcesDirectory

Directory containing exported Joplin resources (matches by filename prefix).


## Outputs

System.String when content is piped or -PassThru is used.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `joplin-links-to-local` - Rewrites Joplin resource links to local attachment paths.


## Source

Defined in: ../profile.d/conversion-modules/document/document-markdown-notes.ps1
