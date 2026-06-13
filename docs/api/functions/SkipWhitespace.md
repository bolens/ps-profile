# SkipWhitespace

## Synopsis

Initializes S-Expressions format conversion utility functions.

## Description

Sets up internal conversion functions for S-Expressions (Lisp-style) format conversions. S-Expressions are a notation for nested tree-structured data using parentheses. Supports conversions between S-Expressions and JSON, YAML, and other formats. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
SkipWhitespace
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. S-Expressions support: - Lists: (item1 item2 item3) - Atoms: strings, numbers, symbols - Nested structures - Quoted strings: "string with spaces" - Comments: ; comment text Reference: https://en.wikipedia.org/wiki/S-expression


## Source

Defined in: ../profile.d/conversion-modules/data/structured/sexpr.ps1
