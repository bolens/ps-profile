# ConvertFrom-FlatBuffersToJson

## Synopsis

Converts FlatBuffers file to JSON format.

## Description

Converts a FlatBuffers binary file back to JSON format. Requires Node.js, the flatbuffers package, and a compiled schema. Note: FlatBuffers requires schema compilation with flatc compiler.

## Signature

```powershell
ConvertFrom-FlatBuffersToJson
```

## Parameters

### -InputPath

The path to the FlatBuffers file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.

### -SchemaPath

The path to the compiled FlatBuffers schema. Required.


## Examples

### Example 1

```powershell
ConvertFrom-FlatBuffersToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `fb-to-json` - Converts FlatBuffers file to JSON format.
- `flatbuffers-to-json` - Converts FlatBuffers file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-schema-flatbuffers.ps1
