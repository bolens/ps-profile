# Initialize-FileConversion-SuperJson

## Synopsis

Initializes SuperJSON format conversion utility functions.

## Description

Sets up internal conversion functions for SuperJSON format, which extends JSON to support additional types. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-SuperJson
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires Node.js and the superjson package. Internal dependencies: helpers-xml.ps1 (for Convert-JsonToXml), helpers-toon.ps1 (for Convert-JsonToToon, Convert-ToonToJson)


## Source

Defined in: ../profile.d/conversion-modules/data/structured/superjson.ps1
