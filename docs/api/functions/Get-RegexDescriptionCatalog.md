# Get-RegexDescriptionCatalog

## Synopsis

Lists built-in natural language regex catalog entries.

## Description

Returns catalog entries that map common descriptions to regex patterns.

## Signature

```powershell
Get-RegexDescriptionCatalog
```

## Parameters

### -Name

Optional catalog entry name to return a single entry.


## Outputs

PSCustomObject or ordered hashtable depending on whether -Name is specified.


## Examples

### Example 1

```powershell
Get-RegexDescriptionCatalog -Name 'name'
```

Lists all supported catalog entries.

### Example 2

```powershell
Get-RegexDescriptionCatalog -Name 'iban'
```

Returns the IBAN catalog entry.

## Aliases

This function has the following aliases:

- `regex-catalog` - Lists built-in natural language regex catalog entries.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
