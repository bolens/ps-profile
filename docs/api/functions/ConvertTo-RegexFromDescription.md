# ConvertTo-RegexFromDescription

## Synopsis

Converts a natural language description into a regular expression pattern.

## Description

Translates common natural language regex descriptions into regular expression patterns. Supports catalog entries such as email, URL, IPv4, and UUID, plus compositional phrases such as "starts with user- followed by digits".

## Signature

```powershell
ConvertTo-RegexFromDescription
```

## Parameters

### -Description

Natural language description of the desired pattern.

### -Anchored

When specified, wraps the resulting pattern with ^ and $ if they are not already present.

### -IgnoreCase

When specified, marks the result as case-insensitive.

### -PatternOnly

When specified, returns only the regex pattern string instead of the full result object.

### -SampleMatch

Sample strings that should match the generated pattern.

### -SampleNoMatch

Sample strings that should not match the generated pattern.

### -UseAi

Uses Ollama to generate the regex pattern instead of rule-based conversion.

### -TryAiFallback

Uses Ollama when the rule-based converter cannot interpret the description.

### -OutputFormat

Output format for results: Object (default), Text, or Json.


## Outputs

PSCustomObject Object containing Pattern, Description, Source, IgnoreCase, Notes, IsValid, CatalogName, NeedsAiFallback, and optional SampleResults members. When -PatternOnly is specified, returns System.String.


## Examples

### Example 1

`powershell
ConvertTo-RegexFromDescription -Description 'email'
    Returns a regex pattern object for email addresses.
``

### Example 2

`powershell
ConvertTo-RegexFromDescription -Description "starts with 'user-' followed by digits" -Anchored -PatternOnly
    Returns an anchored regex pattern string.
``

### Example 3

`powershell
ConvertTo-RegexFromDescription -Description 'iban' -SampleMatch 'DE89370400440532013000' -SampleNoMatch 'not-an-iban'
    Returns a pattern and sample validation results.
``

## Aliases

This function has the following aliases:

- `nl-to-regex` - Converts a natural language description into a regular expression pattern.
- `regex-from-description` - Converts a natural language description into a regular expression pattern.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
