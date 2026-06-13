# Initialize-FileConversion-Toml

## Synopsis

Initializes TOML format conversion utility functions.

## Description

Sets up internal conversion functions for TOML (Tom's Obvious, Minimal Language) format. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-Toml
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires PSToml module for TOML output conversions. Internal Dependencies: - helpers-xml.ps1: Provides Convert-JsonToXml for TOML to XML conversions - helpers-toon.ps1: Provides Convert-JsonToToon for TOML to TOON conversions


## Source

Defined in: ../profile.d/conversion-modules/data/structured/toml.ps1
