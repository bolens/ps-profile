# Get-FileHashValue

## Synopsis

Calculates file hash using specified algorithm.

## Description

Computes cryptographic hash of a file. Defaults to SHA256.

## Signature

```powershell
Get-FileHashValue
```

## Parameters

### -Path

The path to the file to hash.

### -Algorithm

The hash algorithm to use. Valid values are MD5, SHA1, SHA256, SHA384, SHA512. Default is SHA256.

## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `file-hash` - Calculates file hash using specified algorithm.

## Source

Defined in: profile.d\02-files-utilities.ps1
