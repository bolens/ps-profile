# Test-AvroSchemaCompatibility

## Synopsis

Tests compatibility between two Avro schemas.

## Description

Tests whether two Avro schemas are compatible for schema evolution. Checks forward compatibility (reader can read writer's data) and backward compatibility. Requires Node.js and the avsc package.

## Signature

```powershell
Test-AvroSchemaCompatibility
```

## Parameters

### -WriterSchemaPath

The path to the Avro schema file (.avsc) used when writing data.

### -ReaderSchemaPath

The path to the Avro schema file (.avsc) used when reading data.


## Outputs

PSCustomObject with compatibility information including: - Compatible: Overall compatibility status - ForwardCompatible: Whether reader can read writer's data - BackwardCompatible: Whether writer can read reader's data - Errors: Array of any compatibility errors


## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `avro-schema-compat` - Tests compatibility between two Avro schemas.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-schema-avro.ps1
