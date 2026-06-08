# Expand-Snappy

## Synopsis

Decompresses a Snappy compressed file.

## Description

Decompresses a file that was compressed using Snappy compression.

## Signature

```powershell
Expand-Snappy [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the Snappy compressed file.

### -OutputPath

**Type:** [String]

The path for the output decompressed file. If not specified, removes .snappy extension from input path.


## Outputs

System.String Returns the path to the decompressed file.


## Examples

### Example 1

`powershell
Expand-Snappy -InputPath 'data.txt.snappy'
    
    Decompresses data.txt.snappy to data.txt.
``

## Aliases

This function has the following aliases:

- `decompress-snappy` - Decompresses a Snappy compressed file.
- `expand-snappy` - Decompresses a Snappy compressed file.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/snappy.ps1
