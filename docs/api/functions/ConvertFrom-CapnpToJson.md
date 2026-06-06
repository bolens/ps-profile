# ConvertFrom-CapnpToJson

## Synopsis

Converts Cap'n Proto file to JSON format.

## Description

Converts a Cap'n Proto binary file to JSON format. Requires Node.js and the capnp npm package to be installed. Note: Cap'n Proto conversion requires a schema file (.capnp).

## Signature

```powershell
ConvertFrom-CapnpToJson
```

## Parameters

### -InputPath

The path to the Cap'n Proto file (.capnp or .cap extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.

### -SchemaPath

The path to the Cap'n Proto schema file (.capnp extension). Required for decoding.


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `capnp-to-json` - Converts Cap'n Proto file to JSON format.
- `capnproto-to-json` - Converts Cap'n Proto file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-capnp.ps1
