# Initialize-FileConversion-Hjson

## Synopsis

Initializes HJSON format conversion utility functions.

## Description

Sets up internal conversion functions for HJSON (Human JSON) format. HJSON is a more human-friendly format that allows: - Comments (// and /* */) - Unquoted keys - Trailing commas - More lenient whitespace This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-Hjson
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. HJSON is a superset of JSON that is easier to read and write.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/hjson.ps1
