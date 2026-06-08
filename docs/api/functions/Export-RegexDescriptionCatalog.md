# Export-RegexDescriptionCatalog

## Synopsis

Exports the natural language regex catalog to JSON or Markdown.

## Description

Exports catalog entries with patterns, aliases, and notes. Optionally writes to a file.

## Signature

```powershell
Export-RegexDescriptionCatalog
```

## Parameters

### -Format

Export format: Json or Markdown.

### -Path

Optional output file path.


## Outputs

System.String export contents.


## Examples

### Example 1

```powershell
Export-RegexDescriptionCatalog -Format Markdown -Path ./regex-catalog.md
```

Exports the catalog as Markdown.

## Aliases

This function has the following aliases:

- `regex-catalog-export` - Exports the natural language regex catalog to JSON or Markdown.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
