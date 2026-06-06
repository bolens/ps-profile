# ConvertTo-FlatBuffersFromJson

## Synopsis

Converts JSON file to FlatBuffers format.

## Description

Converts a JSON file to FlatBuffers binary format. Requires Node.js, the flatbuffers package, and a compiled schema. Note: FlatBuffers requires schema compilation with flatc compiler.

## Signature

```powershell
ConvertTo-FlatBuffersFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output FlatBuffers file. If not specified, uses input path with .fb extension.

### -SchemaPath

The path to the compiled FlatBuffers schema. Required.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `json-to-fb` - Converts JSON file to FlatBuffers format.
- `json-to-flatbuffers` - Converts JSON file to FlatBuffers format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-schema-flatbuffers.ps1
