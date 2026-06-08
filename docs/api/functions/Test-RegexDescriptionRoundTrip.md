# Test-RegexDescriptionRoundTrip

## Synopsis

Validates natural language regex description round-trip consistency.

## Description

Converts a description to a regex pattern, explains it back to natural language, and scores similarity between the original and explained descriptions.

## Signature

```powershell
Test-RegexDescriptionRoundTrip
```

## Parameters

### -Description

Natural language description to validate.

### -Anchored

When specified, wraps the generated pattern with ^ and $.

### -IgnoreCase

When specified, marks the pattern as case-insensitive.

### -MinimumSimilarity

Minimum similarity score required for a consistent round-trip.

### -OutputFormat

Output format for results: Object (default), Text, or Json.


## Outputs

PSCustomObject with similarity and consistency metrics.


## Examples

### Example 1

`powershell
Test-RegexDescriptionRoundTrip -Description 'email'
    Validates round-trip consistency for an email description.
``

## Aliases

This function has the following aliases:

- `regex-roundtrip` - Validates natural language regex description round-trip consistency.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
