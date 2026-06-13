# Expand-Zlib

## Synopsis

Decompresses a Zlib-compressed file.

## Description

Decompresses a file that was compressed using Zlib (Deflate) compression algorithm.

## Signature

```powershell
Expand-Zlib [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the Zlib-compressed file.

### -OutputPath

**Type:** [String]

The path for the output decompressed file. If not specified, removes .zlib extension from input path.


## Examples

### Example 1

```powershell
Expand-Zlib -InputPath "data.txt.zlib" -OutputPath "data.txt"
```

Decompresses data.txt.zlib to data.txt.

## Aliases

This function has the following aliases:

- `zlib-decompress` - Decompresses a Zlib-compressed file.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/gzip.ps1
