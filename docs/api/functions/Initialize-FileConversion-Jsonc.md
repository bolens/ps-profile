# Initialize-FileConversion-Jsonc

## Synopsis

Initializes JSONC format conversion utility functions.

## Description

Sets up internal conversion functions for JSONC (JSON with Comments) format. JSONC is JSON with C-style comments (// and /* */) support. Commonly used in VS Code settings and configuration files. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-Jsonc
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. JSONC is a superset of JSON that allows comments for documentation.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/jsonc.ps1
