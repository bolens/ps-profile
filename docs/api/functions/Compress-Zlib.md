# Compress-Zlib

## Synopsis

Compresses a file using Zlib compression.

## Description

Compresses a file using Zlib (Deflate) compression algorithm.

## Signature

```powershell
Compress-Zlib [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the file to compress.

### -OutputPath

**Type:** [String]

The path for the output compressed file. If not specified, uses input path with .zlib extension.


## Examples

### Example 1

```powershell
Compress-Zlib -InputPath "data.txt" -OutputPath "data.txt.zlib"
```

Compresses data.txt to data.txt.zlib.

## Aliases

This function has the following aliases:

- `zlib-compress` - Compresses a file using Zlib compression.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/gzip.ps1
