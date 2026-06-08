# Expand-Lzma

## Synopsis

Decompresses an LZMA compressed file.

## Description

Decompresses a file that was compressed using LZMA compression.

## Signature

```powershell
Expand-Lzma [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the LZMA compressed file.

### -OutputPath

**Type:** [String]

The path for the output decompressed file. If not specified, removes .lzma extension from input path.


## Outputs

System.String Returns the path to the decompressed file.


## Examples

### Example 1

```powershell
Expand-Lzma -InputPath 'data.txt.lzma'
```

Decompresses data.txt.lzma to data.txt.

## Aliases

This function has the following aliases:

- `decompress-lzma` - Decompresses an LZMA compressed file.
- `expand-lzma` - Decompresses an LZMA compressed file.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/xz.ps1
