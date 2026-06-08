# Expand-Zstd

## Synopsis

Decompresses a Zstandard (zstd) compressed file.

## Description

Decompresses a file that was compressed using Zstandard (zstd) compression. Requires the zstd command-line tool to be installed.

## Signature

```powershell
Expand-Zstd [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the zstd compressed file.

### -OutputPath

**Type:** [String]

The path for the output decompressed file. If not specified, removes .zst extension from input path.


## Outputs

System.String Returns the path to the decompressed file.


## Examples

### Example 1

```powershell
Expand-Zstd -InputPath 'data.txt.zst'
```

Decompresses data.txt.zst to data.txt.

## Notes

Requires zstd command-line tool (see Get-ConversionToolMissingMessage -ToolName zstd). .EXAMPLE Expand-Zstd -InputPath 'data.txt.zst' Decompresses data.txt.zst to data.txt.


## Aliases

This function has the following aliases:

- `decompress-zstd` - Decompresses a Zstandard (zstd) compressed file.
- `expand-zstd` - Decompresses a Zstandard (zstd) compressed file.
- `uncompress-zstd` - Decompresses a Zstandard (zstd) compressed file.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/zstd.ps1
