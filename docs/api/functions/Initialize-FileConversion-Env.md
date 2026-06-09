# Initialize-FileConversion-Env

## Synopsis

Initializes .env file format conversion utility functions.

## Description

Sets up internal conversion functions for .env file format conversions. .env files are used to store environment variables in key=value format. Supports conversions between .env and JSON, YAML, INI, and other formats. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-Env
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. .env files support comments (lines starting with #) and multi-line values.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/env.ps1
