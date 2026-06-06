# ConvertTo-AvroFromJson

## Synopsis

Converts JSON file to Avro format.

## Description

Converts a JSON file to Avro binary format. Requires Node.js, the avsc package, and a schema file.

## Signature

```powershell
ConvertTo-AvroFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output Avro file. If not specified, uses input path with .avro extension.

### -SchemaPath

The path to the Avro schema file (.avsc). Required.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `json-to-avro` - Converts JSON file to Avro format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-schema-avro.ps1
