# Compare-TextFiles

## Synopsis

Compares two text files and shows differences.

## Description

Compares two text files and displays differences. Uses diff command if available, otherwise shows a line-by-line comparison.

## Signature

```powershell
Compare-TextFiles
```

## Parameters

### -File1

Path to the first file.

### -File2

Path to the second file.


## Outputs

System.Boolean Returns $true if files are identical, $false if different.


## Examples

### Example 1

```powershell
Compare-TextFiles -File1 "file1.txt" -File2 "file2.txt"
```

Compares the two files and shows differences.

## Aliases

This function has the following aliases:

- `compare-files` - Compares two text files and shows differences.
- `diff-files` - Compares two text files and shows differences.


## Source

Defined in: ../profile.d/dev-tools-modules/format/diff.ps1
