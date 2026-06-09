# ConvertFrom-ThriftToJson

## Synopsis

Converts Thrift file to JSON format.

## Description

Converts a Thrift binary file back to JSON format. Requires Node.js, the thrift package, and a compiled schema. Note: Thrift requires schema compilation with thrift compiler.

## Signature

```powershell
ConvertFrom-ThriftToJson
```

## Parameters

### -InputPath

The path to the Thrift file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.

### -SchemaPath

The path to the compiled Thrift schema. Required.


## Examples

### Example 1

```powershell
ConvertFrom-ThriftToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `thrift-to-json` - Converts Thrift file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-schema-thrift.ps1
