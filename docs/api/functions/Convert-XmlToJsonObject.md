# Convert-XmlToJsonObject

## Synopsis

Converts an XML element to a JSON-compatible PowerShell object.

## Description

Recursively converts an XML element and its children to a PowerShell object that can be easily serialized to JSON. Handles arrays for repeated elements and preserves text content.

## Signature

```powershell
Convert-XmlToJsonObject
```

## Parameters

### -Element

The XML element to convert to a JSON object.


## Outputs

PSCustomObject representing the XML structure in JSON-compatible format.


## Examples

No examples provided.

## Source

Defined in: ..\profile.d\02-files-conversion.ps1
