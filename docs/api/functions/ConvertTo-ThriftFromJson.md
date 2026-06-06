# ConvertTo-ThriftFromJson

## Synopsis

Converts JSON file to Thrift format.

## Description

Converts a JSON file to Thrift binary format. Requires Node.js, the thrift package, and a compiled schema. Note: Thrift requires schema compilation with thrift compiler.

## Signature

```powershell
ConvertTo-ThriftFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output Thrift file. If not specified, uses input path with .thrift extension.

### -SchemaPath

The path to the compiled Thrift schema. Required.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `json-to-thrift` - Converts JSON file to Thrift format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-schema-thrift.ps1
