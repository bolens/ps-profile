# Resume-RegexDescriptionSession

## Synopsis

Resumes work from a saved natural language regex session.

## Description

Loads a session file and optionally regenerates tests or re-runs the builder.

## Signature

```powershell
Resume-RegexDescriptionSession
```

## Parameters

### -Path

Path to the session JSON file.

### -Regenerate

When specified, re-converts the stored description instead of using the saved pattern.

### -GenerateTest

When specified, generates a Pester stub from the session.

### -TestPath

Optional output path when -GenerateTest is specified.


## Examples

### Example 1

```powershell
Resume-RegexDescriptionSession -Path ./email.json
```

### Example 2

```powershell
Resume-RegexDescriptionSession -Path ./email.json -GenerateTest -TestPath ./email.tests.ps1
```

## Aliases

This function has the following aliases:

- `regex-session-resume` - Resumes work from a saved natural language regex session.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
