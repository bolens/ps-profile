# ConvertFrom-EdifactToXml

## Synopsis

Converts EDIFACT file to XML format.

## Description

Parses an EDIFACT file and converts it to structured XML format. Each segment becomes an XML element with Tag attribute and Element children.

## Signature

```powershell
ConvertFrom-EdifactToXml
```

## Parameters

### -InputPath

The path to the EDIFACT file (.edifact, .edi, or .edf extension).

### -OutputPath

The path for the output XML file. If not specified, uses input path with .xml extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertFrom-EdifactToXml -InputPath "message.edifact"
    
    Converts message.edifact to message.xml.
``

## Aliases

This function has the following aliases:

- `edifact-to-xml` - Converts EDIFACT file to XML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/edifact.ps1
