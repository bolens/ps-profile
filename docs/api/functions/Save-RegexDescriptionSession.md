# Save-RegexDescriptionSession

## Synopsis

Saves a natural language regex session to a JSON file.

## Description

Persists description, pattern, samples, and builder metadata for later reuse.

## Signature

```powershell
Save-RegexDescriptionSession
```

## Parameters

### -Session

Session object from Start-RegexDescriptionBuilder or New-NaturalLanguageRegexSession.

### -Path

Output JSON file path.


## Examples

### Example 1

```powershell
$builder = Start-RegexDescriptionBuilder -Description 'email' -NonInteractive
```

Save-RegexDescriptionSession -Session $builder.Session -Path ./email.json

## Aliases

This function has the following aliases:

- `regex-session-save` - Saves a natural language regex session to a JSON file.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
