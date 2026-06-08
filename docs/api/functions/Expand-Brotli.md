# Expand-Brotli

## Synopsis

Decompresses a Brotli compressed file.

## Description

Decompresses a file that was compressed using Brotli compression.

## Signature

```powershell
Expand-Brotli [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the Brotli compressed file.

### -OutputPath

**Type:** [String]

The path for the output decompressed file. If not specified, removes .br extension from input path.


## Outputs

System.String Returns the path to the decompressed file.


## Examples

### Example 1

```powershell
Expand-Brotli -InputPath 'data.txt.br'
```

Decompresses data.txt.br to data.txt.

## Aliases

This function has the following aliases:

- `decompress-brotli` - Decompresses a Brotli compressed file.
- `expand-brotli` - Decompresses a Brotli compressed file.
- `uncompress-brotli` - Decompresses a Brotli compressed file.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/brotli.ps1
