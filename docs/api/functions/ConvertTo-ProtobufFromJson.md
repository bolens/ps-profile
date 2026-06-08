# ConvertTo-ProtobufFromJson

## Synopsis

Converts JSON file to Protocol Buffers format.

## Description

Converts a JSON file to Protocol Buffers (protobuf) binary format. Requires Node.js, the protobufjs package, and a schema file.

## Signature

```powershell
ConvertTo-ProtobufFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output Protocol Buffers file. If not specified, uses input path with .pb extension.

### -SchemaPath

The path to the Protocol Buffers schema file (.proto or JSON schema). Required.


## Examples

### Example 1

```powershell
ConvertTo-ProtobufFromJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `json-to-pb` - Converts JSON file to Protocol Buffers format.
- `json-to-protobuf` - Converts JSON file to Protocol Buffers format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-schema-protobuf.ps1
