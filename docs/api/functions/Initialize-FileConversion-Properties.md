# Initialize-FileConversion-Properties

## Synopsis

Initializes Java Properties file format conversion utility functions.

## Description

Sets up internal conversion functions for Java Properties file format conversions. Properties files are used in Java applications to store configuration in key=value format. Supports conversions between Properties and JSON, YAML, INI, and other formats. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-Properties
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Properties files support: - Comments (lines starting with # or !) - Key=value pairs - Escaped characters (\n, \t, \\, \uXXXX for Unicode) - Multi-line values (using trailing backslash) - Whitespace around = is ignored Reference: https://docs.oracle.com/javase/8/docs/api/java/util/Properties.html


## Source

Defined in: ../profile.d/conversion-modules/data/structured/properties.ps1
