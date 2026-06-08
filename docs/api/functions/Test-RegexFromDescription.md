# Test-RegexFromDescription

## Synopsis

Converts a natural language description to regex and tests it against input.

## Description

Generates a regex pattern from a natural language description and immediately tests it against the provided input text.

## Signature

```powershell
Test-RegexFromDescription
```

## Parameters

### -Description

Natural language description of the desired pattern.

### -InputText

Input text to test against the generated pattern.

### -Anchored

When specified, wraps the resulting pattern with ^ and $.

### -IgnoreCase

When specified, performs case-insensitive matching.

### -AllMatches

When specified, returns all matches instead of only the first.

### -UseAi

Uses Ollama to generate the regex pattern.

### -TryAiFallback

Uses Ollama when the rule-based converter cannot interpret the description.


## Outputs

PSCustomObject containing conversion details and match results.


## Examples

### Example 1

```powershell
Test-RegexFromDescription -Description 'email' -Input 'user@example.com'
```

Generates an email regex and tests the input.

## Aliases

This function has the following aliases:

- `regex-test-description` - Converts a natural language description to regex and tests it against input.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
