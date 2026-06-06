# ConvertFrom-Asn1ToJson

## Synopsis

Converts ASN.1 schema file to JSON format.

## Description

Parses an ASN.1 (Abstract Syntax Notation One) schema definition file and converts it to structured JSON format. Supports basic ASN.1 types: INTEGER, OCTET STRING, SEQUENCE, CHOICE, etc.

## Signature

```powershell
ConvertFrom-Asn1ToJson
```

## Parameters

### -InputPath

The path to the ASN.1 file (.asn1 or .asn extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertFrom-Asn1ToJson -InputPath "schema.asn1"
    
    Converts schema.asn1 to schema.json.
``

## Aliases

This function has the following aliases:

- `asn1-to-json` - Converts ASN.1 schema file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/asn1.ps1
