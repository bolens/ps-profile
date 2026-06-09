# Compress-Gzip

## Synopsis

Compresses a file using Gzip compression.

## Description

Compresses a file using Gzip compression algorithm.

## Signature

```powershell
Compress-Gzip [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the file to compress.

### -OutputPath

**Type:** [String]

The path for the output compressed file. If not specified, uses input path with .gz extension.


## Examples

### Example 1

```powershell
Compress-Gzip -InputPath "data.txt" -OutputPath "data.txt.gz"
```

Compresses data.txt to data.txt.gz.

## Aliases

This function has the following aliases:

- `gzip-compress` - Compresses a file using Gzip compression.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/gzip.ps1
