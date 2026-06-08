# Show-RegexDescriptionCatalog

## Synopsis

Displays natural language regex catalog entries in a table.

## Description

Shows catalog entries with names, aliases, and notes. Optionally filters by query.

## Signature

```powershell
Show-RegexDescriptionCatalog
```

## Parameters

### -Query

Optional search text to filter catalog entries.

### -IncludePattern

When specified, includes the regex pattern column in the output table.


## Examples

### Example 1

```powershell
Show-RegexDescriptionCatalog -Query 'search term'
```

Displays all catalog entries.

### Example 2

```powershell
Show-RegexDescriptionCatalog -Query 'phone' -IncludePattern
```

Displays phone-related catalog entries including patterns.

## Aliases

This function has the following aliases:

- `regex-catalog-show` - Displays natural language regex catalog entries in a table.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
