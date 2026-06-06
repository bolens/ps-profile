# Initialize-FileConversion-BinarySchemaThrift

## Synopsis

Initializes Thrift schema conversion utility functions.

## Description

Sets up internal conversion functions for Thrift format conversions. Supports bidirectional conversions between JSON and Thrift. This function is called automatically by Initialize-FileConversion-BinarySchema.

## Signature

```powershell
Initialize-FileConversion-BinarySchemaThrift
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires Node.js and the thrift npm package. Note: Thrift requires schema compilation with thrift compiler.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-schema-thrift.ps1
