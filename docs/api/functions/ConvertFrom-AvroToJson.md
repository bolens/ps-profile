# ConvertFrom-AvroToJson

## Synopsis

Converts Avro file to JSON format.

## Description

Converts an Avro binary file back to JSON format. Requires Node.js, the avsc package, and a schema file.

## Signature

```powershell
ConvertFrom-AvroToJson
```

## Parameters

### -InputPath

The path to the Avro file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.

### -SchemaPath

The path to the Avro schema file (.avsc). Required.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `avro-to-json` - Converts Avro file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-schema-avro.ps1
