# ConvertFrom-Asn1ToXml

## Synopsis

Converts ASN.1 schema file to XML format.

## Description

Parses an ASN.1 schema definition file and converts it to structured XML format. Each type becomes an XML element with TypeSpec and Components.

## Signature

```powershell
ConvertFrom-Asn1ToXml
```

## Parameters

### -InputPath

The path to the ASN.1 file (.asn1 or .asn extension).

### -OutputPath

The path for the output XML file. If not specified, uses input path with .xml extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertFrom-Asn1ToXml -InputPath "schema.asn1"
```

Converts schema.asn1 to schema.xml.

## Aliases

This function has the following aliases:

- `asn1-to-xml` - Converts ASN.1 schema file to XML format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/asn1.ps1
