# Convert-ToonToJson

## Synopsis

Converts TOON format to a JSON-compatible PowerShell object.

## Description

Parses TOON (Token-Oriented Object Notation) format and converts it back to a PowerShell object that can be serialized to JSON.

## Signature

```powershell
Convert-ToonToJson
```

## Parameters

### -ToonString

The TOON format string to parse.


## Outputs

PowerShell object representing the parsed TOON data.


## Examples

### Example 1

```powershell
Convert-ToonToJson -ToonString 'value'
```

## Source

Defined in: ../profile.d/conversion-modules/helpers/helpers-toon.ps1
