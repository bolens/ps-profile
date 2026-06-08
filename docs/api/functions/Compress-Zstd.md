# Compress-Zstd

## Synopsis

Compresses a file using Zstandard (zstd) compression.

## Description

Compresses a file using the Zstandard (zstd) compression algorithm. Zstandard provides a good balance between compression ratio and speed. Requires the zstd command-line tool to be installed.

## Signature

```powershell
Compress-Zstd [String]$InputPath, [String]$OutputPath, [Int32]$CompressionLevel
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the file to compress.

### -OutputPath

**Type:** [String]

The path for the output compressed file. If not specified, uses input path with .zst extension.

### -CompressionLevel

**Type:** [Int32]

The compression level (1-22, or -1 for default). Higher values provide better compression but are slower. Default is 3.


## Outputs

System.String Returns the path to the compressed file.


## Examples

### Example 1

`powershell
Compress-Zstd -InputPath 'data.txt'
    
    Compresses data.txt to data.txt.zst.
``

### Example 2

`powershell
Compress-Zstd -InputPath 'data.txt' -CompressionLevel 10
    
    Compresses data.txt with compression level 10.
``

## Notes

Requires zstd command-line tool (see Get-ConversionToolMissingMessage -ToolName zstd). .OUTPUTS System.String Returns the path to the compressed file.


## Aliases

This function has the following aliases:

- `compress-zstd` - Compresses a file using Zstandard (zstd) compression.
- `zstd` - Compresses a file using Zstandard (zstd) compression.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/zstd.ps1
