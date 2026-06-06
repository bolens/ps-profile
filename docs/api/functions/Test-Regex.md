# Test-Regex

## Synopsis

Tests a regular expression against input text.

## Description

Tests a regular expression pattern against input text and returns match results.

## Signature

```powershell
Test-Regex
```

## Parameters

### -Pattern

The regular expression pattern to test.

### -Input

The input text to test against.

### -AllMatches

If specified, returns all matches instead of just the first.

### -IgnoreCase

If specified, performs case-insensitive matching.


## Outputs

PSCustomObject Object containing match information (Success, Value, Index, Length, Groups).


## Examples

### Example 1

`powershell
Test-Regex -Pattern "\d+" -Input "Hello 123 World"
    Tests the pattern against the input and returns match details.
``

### Example 2

`powershell
Test-Regex -Pattern "\w+" -Input "Hello World" -AllMatches
    Returns all word matches in the input.
``

## Aliases

This function has the following aliases:

- `regex-test` - Tests a regular expression against input text.


## Source

Defined in: ../profile.d/dev-tools-modules/format/regex.ps1
