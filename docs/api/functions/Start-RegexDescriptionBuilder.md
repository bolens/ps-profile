# Start-RegexDescriptionBuilder

## Synopsis

Builds a natural language regex description interactively or from segments.

## Description

Guides you through building a regex description from catalog entries, composed segments, or either/or options. Converts the result and optionally tests samples.

## Signature

```powershell
Start-RegexDescriptionBuilder
```

## Parameters

### -Description

Uses a pre-built description instead of prompting interactively.

### -Segments

Ordered phrase segments for non-interactive composition.

### -Alternation

When specified with -Segments, builds an either/or description.

### -Anchored

When specified, anchors the generated pattern to the full input.

### -IgnoreCase

When specified, marks the pattern as case-insensitive.

### -SampleMatch

Expected matching samples for the generated pattern.

### -SampleNoMatch

Expected non-matching samples for the generated pattern.

### -SessionPath

Optional path for saving the builder session as JSON.

### -SaveSession

When specified, saves the session to -SessionPath or an auto-generated file.

### -NonInteractive

Requires -Description or -Segments and skips prompts.

### -OutputFormat

Output format for results: Object (default), Text, or Json.


## Outputs

PSCustomObject with Description, Pattern, Conversion, Session, and optional SessionPath members.


## Examples

### Example 1

`powershell
Start-RegexDescriptionBuilder
    Starts the interactive regex description builder.
``

### Example 2

`powershell
Start-RegexDescriptionBuilder -Segments "starts with 'svc-'", 'digits' -Anchored -NonInteractive
    Builds and converts a description without prompts.
``

### Example 3

`powershell
Start-RegexDescriptionBuilder -Description 'email' -SaveSession -SessionPath ./email-regex.json
    Builds and persists a regex session file.
``

## Aliases

This function has the following aliases:

- `regex-builder` - Builds a natural language regex description interactively or from segments.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
