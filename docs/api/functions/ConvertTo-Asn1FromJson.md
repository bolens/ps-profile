# ConvertTo-Asn1FromJson

## Synopsis

Converts JSON file to ASN.1 format.

## Description

Converts a structured JSON file (with ASN.1 module structure) to ASN.1 schema definition format. The JSON should have a Module structure with Types containing Name and Specification.

## Signature

```powershell
ConvertTo-Asn1FromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output ASN.1 file. If not specified, uses input path with .asn1 extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertTo-Asn1FromJson -InputPath "schema.json"
```

Converts schema.json to schema.asn1.

## Aliases

This function has the following aliases:

- `json-to-asn1` - Converts JSON file to ASN.1 format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/asn1.ps1
