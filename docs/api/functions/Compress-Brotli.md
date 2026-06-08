# Compress-Brotli

## Synopsis

Compresses a file using Brotli compression.

## Description

Compresses a file using the Brotli compression algorithm. Brotli is a modern compression algorithm that provides better compression ratios than Gzip.

## Signature

```powershell
Compress-Brotli [String]$InputPath, [String]$OutputPath, [CompressionLevel]$Quality
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the file to compress.

### -OutputPath

**Type:** [String]

The path for the output compressed file. If not specified, uses input path with .br extension.

### -Quality

**Type:** [CompressionLevel]

The compression quality level (Fastest, Optimal, NoCompression, SmallestSize). Default is Optimal.


## Outputs

System.String Returns the path to the compressed file.


## Examples

### Example 1

```powershell
Compress-Brotli -InputPath 'data.txt'
```

Compresses data.txt to data.txt.br.

### Example 2

```powershell
Compress-Brotli -InputPath 'data.txt' -Quality Fastest
```

Compresses data.txt with fastest compression.

## Aliases

This function has the following aliases:

- `brotli` - Compresses a file using Brotli compression.
- `compress-brotli` - Compresses a file using Brotli compression.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/brotli.ps1
