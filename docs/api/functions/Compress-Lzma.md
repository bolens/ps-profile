# Compress-Lzma

## Synopsis

Compresses a file using LZMA compression.

## Description

Compresses a file using the LZMA compression format. LZMA provides high compression ratios.

## Signature

```powershell
Compress-Lzma [String]$InputPath, [String]$OutputPath, [Int32]$CompressionLevel
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the file to compress.

### -OutputPath

**Type:** [String]

The path for the output compressed file. If not specified, uses input path with .lzma extension.

### -CompressionLevel

**Type:** [Int32]

The compression level (0-9). Default is 6. Higher levels provide better compression but are slower.


## Outputs

System.String Returns the path to the compressed file.


## Examples

### Example 1

`powershell
Compress-Lzma -InputPath 'data.txt'
    
    Compresses data.txt to data.txt.lzma.
``

## Aliases

This function has the following aliases:

- `compress-lzma` - Compresses a file using LZMA compression.
- `lzma` - Compresses a file using LZMA compression.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/xz.ps1
