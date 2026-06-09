# ConvertFrom-ProtobufToJson

## Synopsis

Converts Protocol Buffers file to JSON format.

## Description

Converts a Protocol Buffers (protobuf) binary file back to JSON format. Requires Node.js, the protobufjs package, and a schema file.

## Signature

```powershell
ConvertFrom-ProtobufToJson
```

## Parameters

### -InputPath

The path to the Protocol Buffers file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.

### -SchemaPath

The path to the Protocol Buffers schema file (.proto or JSON schema). Required.


## Examples

### Example 1

```powershell
ConvertFrom-ProtobufToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `pb-to-json` - Converts Protocol Buffers file to JSON format.
- `protobuf-to-json` - Converts Protocol Buffers file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-schema-protobuf.ps1
