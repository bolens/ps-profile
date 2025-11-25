# Get-FileHashValue

## Synopsis

Calculates cryptographic hash of a file.

## Description

Computes the hash value of a file using the specified cryptographic algorithm. Useful for file integrity verification and duplicate detection.

## Signature

```powershell
Get-FileHashValue
```

## Parameters

### -Path

The path to the file to hash. Must be a valid file path.

### -Algorithm

The hash algorithm to use. Valid values are MD5, SHA1, SHA256, SHA384, SHA512. Default is SHA256.


## Inputs

System.String File path as a string. .OUTPUTS Microsoft.PowerShell.Commands.FileHashInfo Object containing the hash algorithm, hash value, and file path. .EXAMPLE PS C:\> Get-FileHashValue -Path "C:\temp\file.txt" Algorithm Hash Path --------- ---- ---- SHA256 4A5B8C9D... C:\temp\file.txt Calculates SHA256 hash of file.txt. .EXAMPLE PS C:\> file-hash "C:\temp\file.txt" -Algorithm MD5 Algorithm Hash Path --------- ---- ---- MD5 9F8E7D6C... C:\temp\file.txt Calculates MD5 hash of file.txt using the alias. .EXAMPLE PS C:\> Get-FileHashValue -Path "nonexistent.txt" WARNING: File not found: nonexistent.txt Shows warning when file doesn't exist. .NOTES This function uses the built-in Get-FileHash cmdlet for actual hash computation. For large files, hash calculation may take some time.


## Outputs

Microsoft.PowerShell.Commands.FileHashInfo Object containing the hash algorithm, hash value, and file path. .EXAMPLE PS C:\> Get-FileHashValue -Path "C:\temp\file.txt" Algorithm Hash Path --------- ---- ---- SHA256 4A5B8C9D... C:\temp\file.txt Calculates SHA256 hash of file.txt. .EXAMPLE PS C:\> file-hash "C:\temp\file.txt" -Algorithm MD5 Algorithm Hash Path --------- ---- ---- MD5 9F8E7D6C... C:\temp\file.txt Calculates MD5 hash of file.txt using the alias. .EXAMPLE PS C:\> Get-FileHashValue -Path "nonexistent.txt" WARNING: File not found: nonexistent.txt Shows warning when file doesn't exist.


## Examples

### Example 1

`powershell
PS C:\> Get-FileHashValue -Path "C:\temp\file.txt"
    Algorithm       Hash                                                                   Path
    ---------       ----                                                                   ----
    SHA256          4A5B8C9D...                                                           C:\temp\file.txt

    Calculates SHA256 hash of file.txt.
``

### Example 2

`powershell
PS C:\> file-hash "C:\temp\file.txt" -Algorithm MD5
    Algorithm       Hash                                                                   Path
    ---------       ----                                                                   ----
    MD5             9F8E7D6C...                                                           C:\temp\file.txt

    Calculates MD5 hash of file.txt using the alias.
``

### Example 3

`powershell
PS C:\> Get-FileHashValue -Path "nonexistent.txt"
    WARNING: File not found: nonexistent.txt

    Shows warning when file doesn't exist.
``

## Notes

This function uses the built-in Get-FileHash cmdlet for actual hash computation. For large files, hash calculation may take some time.


## Related Links

- Get-FileHash
    Get-FileSize
    Test-Path


## Aliases

This function has the following aliases:

- `file-hash` - Calculates cryptographic hash of a file.


## Source

Defined in: ..\profile.d\02-files-utilities.ps1
