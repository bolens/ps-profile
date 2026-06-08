# _ConvertTo-ToonFromJson

## Synopsis

Initializes TOON format conversion utility functions.

## Description

Sets up internal conversion functions for TOON (Token-Oriented Object Notation) format. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
_ConvertTo-ToonFromJson [String]$InputPath, [String]$OutputPath
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Internal dependencies: helpers-xml.ps1 (for Convert-JsonToXml), helpers-toon.ps1 (for Convert-JsonToToon, Convert-ToonToJson)


## Source

Defined in: ../profile.d/conversion-modules/data/structured/toon.ps1
