# Expand-Gzip

## Synopsis

Decompresses a Gzip-compressed file.

## Description

Decompresses a file that was compressed using Gzip compression algorithm.

## Signature

```powershell
Expand-Gzip [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the Gzip-compressed file.

### -OutputPath

**Type:** [String]

The path for the output decompressed file. If not specified, removes .gz extension from input path.


## Examples

### Example 1

```powershell
Expand-Gzip -InputPath "data.txt.gz" -OutputPath "data.txt"
```

Decompresses data.txt.gz to data.txt.

## Aliases

This function has the following aliases:

- `gunzip` - Decompresses a Gzip-compressed file.
- `gzip-decompress` - Decompresses a Gzip-compressed file.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/gzip.ps1
