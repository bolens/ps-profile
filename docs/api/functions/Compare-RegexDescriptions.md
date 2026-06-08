# Compare-RegexDescriptions

## Synopsis

Compares two natural language regex descriptions.

## Description

Shows token differences, similarity score, and optional generated pattern comparison.

## Signature

```powershell
Compare-RegexDescriptions
```

## Parameters

### -Left

First natural language description.

### -Right

Second natural language description.

### -IncludePatterns

When specified, also compares generated regex patterns.

### -ShowDiff

When specified, writes a color-coded diff summary to the host.

### -OutputFormat

Output format for results: Object (default), Text, or Json.


## Examples

### Example 1

```powershell
Compare-RegexDescriptions -Left 'email' -Right 'email address' -IncludePatterns
```

## Aliases

This function has the following aliases:

- `regex-compare` - Compares two natural language regex descriptions.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
