# Initialize-FileConversion-CoreBasicCsv

## Synopsis

Initializes CSV format conversion utility functions.

## Description

Sets up internal conversion functions for CSV format conversions. Supports bidirectional conversions between CSV and JSON, and CSV and YAML. This function is called automatically by Initialize-FileConversion-CoreBasic.

## Signature

```powershell
Initialize-FileConversion-CoreBasicCsv
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. CSV to YAML conversion requires yq command-line tool.


## Source

Defined in: ../profile.d/conversion-modules/data/core/csv.ps1
