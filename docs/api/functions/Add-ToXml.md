# Add-ToXml

## Synopsis

Converts a JSON object to XML format.

## Description

Converts a PowerShell object (from JSON) to XML format.

## Signature

```powershell
Add-ToXml
```

## Parameters

### -JsonObject

The PowerShell object to convert to XML.

### -RootName

The root element name for the XML document.


## Outputs

System.Xml.XmlDocument representing the XML structure.


## Examples

### Example 1

```powershell
Convert-JsonToXml -JsonObject 'value'
```

## Source

Defined in: ../profile.d/conversion-modules/helpers/helpers-xml.ps1
