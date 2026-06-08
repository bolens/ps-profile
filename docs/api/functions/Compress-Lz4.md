# Compress-Lz4

## Synopsis

Compresses a file using LZ4 compression.

## Description

Compresses a file using the LZ4 compression algorithm. LZ4 is a fast compression algorithm with high compression and decompression speeds.

## Signature

```powershell
Compress-Lz4 [String]$InputPath, [String]$OutputPath, [Int32]$CompressionLevel
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the file to compress.

### -OutputPath

**Type:** [String]

The path for the output compressed file. If not specified, uses input path with .lz4 extension.

### -CompressionLevel

**Type:** [Int32]

The compression level (1-9). Default is 1 (fastest). Higher levels provide better compression but are slower.


## Outputs

System.String Returns the path to the compressed file.


## Examples

### Example 1

`powershell
Compress-Lz4 -InputPath 'data.txt'
    
    Compresses data.txt to data.txt.lz4.
``

### Example 2

`powershell
Compress-Lz4 -InputPath 'data.txt' -CompressionLevel 9
    
    Compresses data.txt with maximum compression level.
``

## Aliases

This function has the following aliases:

- `compress-lz4` - Compresses a file using LZ4 compression.
- `lz4` - Compresses a file using LZ4 compression.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/lz4.ps1
