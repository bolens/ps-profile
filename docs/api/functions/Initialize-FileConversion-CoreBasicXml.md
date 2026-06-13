# Initialize-FileConversion-CoreBasicXml

## Synopsis

Initializes XML format conversion utility functions.

## Description

Sets up internal conversion functions for XML format conversions. Supports conversion from XML to JSON. This function is called automatically by Initialize-FileConversion-CoreBasic.

## Signature

```powershell
Initialize-FileConversion-CoreBasicXml
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. XML to JSON conversion uses a helper function Convert-XmlToJsonObject.


## Source

Defined in: ../profile.d/conversion-modules/data/core/xml.ps1
