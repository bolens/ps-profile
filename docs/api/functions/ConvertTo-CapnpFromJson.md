# ConvertTo-CapnpFromJson

## Synopsis

Converts JSON file to Cap'n Proto format.

## Description

Converts a JSON file to Cap'n Proto binary format. Cap'n Proto is a fast binary serialization format. Requires Node.js and the capnp npm package to be installed. Note: Cap'n Proto conversion requires a schema file (.capnp).

## Signature

```powershell
ConvertTo-CapnpFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output Cap'n Proto file. If not specified, uses input path with .capnp extension.

### -SchemaPath

The path to the Cap'n Proto schema file (.capnp extension). Required for encoding.


## Examples

### Example 1

```powershell
ConvertTo-CapnpFromJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `json-to-capnp` - Converts JSON file to Cap'n Proto format.
- `json-to-capnproto` - Converts JSON file to Cap'n Proto format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-capnp.ps1
