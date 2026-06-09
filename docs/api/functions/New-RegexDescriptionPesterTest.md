# New-RegexDescriptionPesterTest

## Synopsis

Generates a Pester test stub for a natural language regex description.

## Description

Creates a standalone Pester test file from a description, pattern, and sample inputs.

## Signature

```powershell
New-RegexDescriptionPesterTest
```

## Parameters

### -Description

Natural language description of the desired pattern.

### -Pattern

Optional pre-generated regex pattern.

### -SampleMatch

Sample strings expected to match.

### -SampleNoMatch

Sample strings expected not to match.

### -Path

Optional output file path for the generated test stub.


## Examples

### Example 1

```powershell
New-RegexDescriptionPesterTest -Description 'email' -SampleMatch 'user@example.com' -SampleNoMatch 'invalid'
```

### Example 2

```powershell
New-RegexDescriptionPesterTest -Description 'uuid' -Path ./uuid.tests.ps1
```

## Aliases

This function has the following aliases:

- `regex-generate-test` - Generates a Pester test stub for a natural language regex description.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
