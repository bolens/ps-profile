# Parse-ToonLines

## Synopsis

Parses TOON format lines into a PowerShell object structure.

## Description

Recursively parses TOON format lines, handling nested objects and arrays. This is an internal helper function used by Convert-ToonToJson.

## Signature

```powershell
Parse-ToonLines
```

## Parameters

### -Lines

Array of TOON format lines to parse.

### -Index

Starting index in the lines array.

### -BaseIndent

Base indentation level for the current parsing context.


## Outputs

Hashtable with 'Object' (the parsed object) and 'Index' (the next index to process). .EXAMPLE Parse-ToonLines


## Examples

### Example 1

`powershell
Parse-ToonLines
``

## Source

Defined in: ../profile.d/conversion-modules/helpers/helpers-toon.ps1
