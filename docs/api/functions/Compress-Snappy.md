# Compress-Snappy

## Synopsis

Compresses a file using Snappy compression.

## Description

Compresses a file using the Snappy compression algorithm. Snappy is a fast compression algorithm developed by Google, optimized for speed.

## Signature

```powershell
Compress-Snappy [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the file to compress.

### -OutputPath

**Type:** [String]

The path for the output compressed file. If not specified, uses input path with .snappy extension.


## Outputs

System.String Returns the path to the compressed file.


## Examples

### Example 1

```powershell
Compress-Snappy -InputPath 'data.txt'
```

Compresses data.txt to data.txt.snappy.

## Aliases

This function has the following aliases:

- `compress-snappy` - Compresses a file using Snappy compression.
- `snappy` - Compresses a file using Snappy compression.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/snappy.ps1
