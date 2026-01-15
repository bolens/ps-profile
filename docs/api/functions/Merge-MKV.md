# Merge-MKV

## Synopsis

Merges multiple MKV files into one.

## Description

Merges multiple MKV files using mkvmerge (from mkvtoolnix). Preserves all tracks and metadata from source files.

## Signature

```powershell
Merge-MKV
```

## Parameters

### -InputPaths

Array of input MKV file paths.

### -OutputPath

Path to the output merged MKV file.


## Outputs

System.String. Path to the merged MKV file.


## Examples

### Example 1

`powershell
Merge-MKV -InputPaths @("part1.mkv", "part2.mkv") -OutputPath "complete.mkv"
        
        Merges part1.mkv and part2.mkv into complete.mkv.
``

## Source

Defined in: ..\profile.d\media-tools.ps1
