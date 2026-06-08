# Compress-Xz

## Synopsis

Compresses a file using XZ compression.

## Description

Compresses a file using the XZ compression format (LZMA2 algorithm). XZ provides high compression ratios.

## Signature

```powershell
Compress-Xz [String]$InputPath, [String]$OutputPath, [Int32]$CompressionLevel
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the file to compress.

### -OutputPath

**Type:** [String]

The path for the output compressed file. If not specified, uses input path with .xz extension.

### -CompressionLevel

**Type:** [Int32]

The compression level (0-9). Default is 6. Higher levels provide better compression but are slower.


## Outputs

System.String Returns the path to the compressed file.


## Examples

### Example 1

```powershell
Compress-Xz -InputPath 'data.txt'
```

Compresses data.txt to data.txt.xz.

### Example 2

```powershell
Compress-Xz -InputPath 'data.txt' -CompressionLevel 9
```

Compresses data.txt with maximum compression level.

## Aliases

This function has the following aliases:

- `compress-xz` - Compresses a file using XZ compression.
- `xz` - Compresses a file using XZ compression.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/xz.ps1
