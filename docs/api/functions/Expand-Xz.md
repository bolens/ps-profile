# Expand-Xz

## Synopsis

Decompresses an XZ compressed file.

## Description

Decompresses a file that was compressed using XZ compression.

## Signature

```powershell
Expand-Xz [String]$InputPath, [String]$OutputPath
```

## Parameters

### -InputPath

**Type:** [String]

**Attributes:** Mandatory

The path to the XZ compressed file.

### -OutputPath

**Type:** [String]

The path for the output decompressed file. If not specified, removes .xz extension from input path.


## Outputs

System.String Returns the path to the decompressed file.


## Examples

### Example 1

`powershell
Expand-Xz -InputPath 'data.txt.xz'
    
    Decompresses data.txt.xz to data.txt.
``

## Aliases

This function has the following aliases:

- `decompress-xz` - Decompresses an XZ compressed file.
- `expand-xz` - Decompresses an XZ compressed file.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/xz.ps1
