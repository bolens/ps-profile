# ConvertFrom-AvroToJsonWithSchemaEvolution

## Synopsis

Converts Avro file to JSON format using schema evolution.

## Description

Converts an Avro binary file to JSON format using schema evolution. Allows reading data written with one schema using a different (compatible) schema. Requires Node.js, the avsc package, and schema files.

## Signature

```powershell
ConvertFrom-AvroToJsonWithSchemaEvolution
```

## Parameters

### -InputPath

The path to the Avro file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.

### -WriterSchemaPath

The path to the Avro schema file (.avsc) used when writing the data. Optional if ReaderSchemaPath is provided.

### -ReaderSchemaPath

The path to the Avro schema file (.avsc) to use when reading the data. Optional if WriterSchemaPath is provided. If only one schema is provided, it will be used for both reading and writing.


## Examples

### Example 1

`powershell
ConvertFrom-AvroToJsonWithSchemaEvolution -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `avro-to-json-evolve` - Converts Avro file to JSON format using schema evolution.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-schema-avro.ps1
