# Search-RegexDescriptions

## Synopsis

Searches natural language regex catalog entries.

## Description

Finds catalog entries whose names or aliases match a query string.

## Signature

```powershell
Search-RegexDescriptions
```

## Parameters

### -Query

Search text to match against catalog names and aliases.


## Outputs

PSCustomObject[] with Name, Pattern, Aliases, Notes, and MatchType members.


## Examples

### Example 1

`powershell
Search-RegexDescriptions -Query 'phone'
    Finds catalog entries related to phone numbers.
``

## Aliases

This function has the following aliases:

- `regex-catalog-search` - Searches natural language regex catalog entries.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
