# Explain-RegexPattern

## Synopsis

Explains a regular expression pattern in plain language.

## Description

Reverse direction of the natural language regex converter. Maps known catalog patterns back to descriptions and decomposes common regex constructs.

## Signature

```powershell
Explain-RegexPattern
```

## Parameters

### -Pattern

Regular expression pattern to explain.

### -Detailed

When specified, includes per-component explanations.

### -UseAi

Uses Ollama to generate the explanation instead of rule-based decomposition.

### -OutputFormat

Output format for results: Object (default), Text, or Json.


## Outputs

PSCustomObject, System.String, or JSON depending on -OutputFormat.


## Examples

### Example 1

```powershell
Explain-RegexPattern -Pattern '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
```

Explains an email regex pattern.

### Example 2

```powershell
Explain-RegexPattern -Pattern '^user-\d+$' -OutputFormat Text
```

Returns a plain-text explanation.

## Aliases

This function has the following aliases:

- `regex-explain` - Explains a regular expression pattern in plain language.
- `regex-to-description` - Explains a regular expression pattern in plain language.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
