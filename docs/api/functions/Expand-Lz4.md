# Expand-Lz4

## Synopsis

Decompresses an LZ4 compressed file.

## Description

Decompresses a file that was compressed using LZ4 compression.

## Signature

```powershell
Expand-Lz4 [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the LZ4 compressed file.

### -OutputPath

**Type:** [String]

The path for the output decompressed file. If not specified, removes .lz4 extension from input path.


## Outputs

System.String Returns the path to the decompressed file.


## Examples

### Example 1

`powershell
Expand-Lz4 -InputPath 'data.txt.lz4'
    
    Decompresses data.txt.lz4 to data.txt.
``

## Aliases

This function has the following aliases:

- `decompress-lz4` - Decompresses an LZ4 compressed file.
- `expand-lz4` - Decompresses an LZ4 compressed file.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/lz4.ps1
