# Convert-JsonToXml

## Synopsis

Converts a JSON object to XML format.

## Description

Converts a PowerShell object (from JSON) to XML format.

## Signature

```powershell
Convert-JsonToXml
```

## Parameters

### -JsonObject

The PowerShell object to convert to XML.

### -RootName

The root element name for the XML document.


## Outputs

System.Xml.XmlDocument representing the XML structure. .EXAMPLE Convert-JsonToXml


## Examples

### Example 1

`powershell
Convert-JsonToXml
``

## Source

Defined in: ../profile.d/conversion-modules/helpers/helpers-xml.ps1
