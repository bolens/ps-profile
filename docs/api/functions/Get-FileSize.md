# Get-FileSize

## Synopsis

Shows human-readable file size.

## Description

Displays the size of a file in human-readable format with appropriate units (bytes, KB, MB, GB, TB). Automatically chooses the most appropriate unit.

## Signature

```powershell
Get-FileSize
```

## Parameters

### -Path

The path to the file to check size. Must be a valid file path.


## Inputs

System.String File path as a string. .OUTPUTS System.String Human-readable file size with unit. .EXAMPLE PS C:\> Get-FileSize -Path "C:\temp\largefile.iso" 4.25 GB Shows the size of a large ISO file in GB. .EXAMPLE PS C:\> filesize "C:\temp\script.ps1" 2.34 KB Shows the size of a PowerShell script using the alias. .EXAMPLE PS C:\> Get-FileSize -Path "C:\temp\small.txt" 145 bytes Shows the size of a small text file in bytes. .EXAMPLE PS C:\> Get-FileSize -Path "nonexistent.txt" Get-FileSize : File not found: nonexistent.txt At line:1 char:1 Shows error when file doesn't exist. .NOTES File sizes are displayed with 2 decimal places for larger units. Uses the file's Length property from Get-Item.


## Outputs

System.String Human-readable file size with unit. .EXAMPLE PS C:\> Get-FileSize -Path "C:\temp\largefile.iso" 4.25 GB Shows the size of a large ISO file in GB. .EXAMPLE PS C:\> filesize "C:\temp\script.ps1" 2.34 KB Shows the size of a PowerShell script using the alias. .EXAMPLE PS C:\> Get-FileSize -Path "C:\temp\small.txt" 145 bytes Shows the size of a small text file in bytes. .EXAMPLE PS C:\> Get-FileSize -Path "nonexistent.txt" Get-FileSize : File not found: nonexistent.txt At line:1 char:1 Shows error when file doesn't exist.


## Examples

### Example 1

`powershell
PS C:\> Get-FileSize -Path "C:\temp\largefile.iso"
    4.25 GB

    Shows the size of a large ISO file in GB.
``

### Example 2

`powershell
PS C:\> filesize "C:\temp\script.ps1"
    2.34 KB

    Shows the size of a PowerShell script using the alias.
``

### Example 3

`powershell
PS C:\> Get-FileSize -Path "C:\temp\small.txt"
    145 bytes

    Shows the size of a small text file in bytes.
``

### Example 4

`powershell
PS C:\> Get-FileSize -Path "nonexistent.txt"
    Get-FileSize : File not found: nonexistent.txt
    At line:1 char:1

    Shows error when file doesn't exist.
``

## Notes

File sizes are displayed with 2 decimal places for larger units. Uses the file's Length property from Get-Item.


## Related Links

- Get-Item
    Get-FileHashValue
    Test-Path


## Aliases

This function has the following aliases:

- `filesize` - Shows human-readable file size.


## Source

Defined in: ..\profile.d\02-files-utilities.ps1
