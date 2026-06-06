# Initialize-FileConversion-BinaryProtocolCapnp

## Synopsis

Initializes Cap'n Proto format conversion utility functions.

## Description

Sets up internal conversion functions for Cap'n Proto format conversions. Cap'n Proto is a fast binary serialization format similar to Protocol Buffers but faster. Supports bidirectional conversions between JSON and Cap'n Proto binary format. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-BinaryProtocolCapnp
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires Node.js and the capnp npm package to be installed.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-capnp.ps1
