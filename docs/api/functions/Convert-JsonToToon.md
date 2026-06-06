# Convert-JsonToToon

## Synopsis

Converts a JSON object to TOON format.

## Description

Converts a PowerShell object (from JSON) to TOON (Token-Oriented Object Notation) format, which removes redundant JSON syntax like brackets and braces to reduce token usage.

## Signature

```powershell
Convert-JsonToToon
```

## Parameters

### -JsonObject

The PowerShell object to convert to TOON format.

### -Indent

The indentation level for nested structures (internal use).


## Outputs

String representing the TOON format.


## Examples

No examples provided.

## Source

Defined in: ../profile.d/conversion-modules/helpers/helpers-toon.ps1
