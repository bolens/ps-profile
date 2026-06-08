# Import-RegexDescriptionSession

## Synopsis

Loads a saved natural language regex session from a JSON file.

## Description

Imports a previously saved regex builder session.

## Signature

```powershell
Import-RegexDescriptionSession
```

## Parameters

### -Path

Path to the session JSON file.


## Examples

### Example 1

`powershell
Import-RegexDescriptionSession -Path ./email.json
``

## Aliases

This function has the following aliases:

- `regex-session-import` - Loads a saved natural language regex session from a JSON file.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
