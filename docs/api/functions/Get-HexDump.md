# Get-HexDump

## Synopsis

Shows hexadecimal dump of a file's contents.

## Description

Displays the contents of a file in hexadecimal format with ASCII representation. Useful for examining binary files, debugging file formats, or low-level file analysis.

## Signature

```powershell
Get-HexDump
```

## Parameters

### -Path

The path to the file to dump. Must be a valid file path.


## Inputs

System.String File path as a string. .OUTPUTS Microsoft.PowerShell.Commands.ByteCollection Hexadecimal representation of file contents. .EXAMPLE PS C:\> Get-HexDump -Path "C:\temp\binaryfile.exe" Offset 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F ------ ----------------------------------------------- 00000000 4D 5A 90 00 03 00 00 00 04 00 00 00 FF FF 00 00 MZ.............. Shows hex dump of an executable file. .EXAMPLE PS C:\> hex-dump "C:\temp\data.bin" Offset 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F ------ ----------------------------------------------- 00000000 48 65 6C 6C 6F 20 57 6F 72 6C 64 21 00 Hello World!. Shows hex dump of a binary file using the alias. .EXAMPLE PS C:\> Get-HexDump -Path "C:\temp\textfile.txt" Offset 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F ------ ----------------------------------------------- 00000000 48 65 6C 6C 6F 2C 20 57 6F 72 6C 64 21 0D 0A Hello, World!.. Shows hex dump of a text file (note the CRLF line endings). .NOTES This function uses the built-in Format-Hex cmdlet. Large files may produce extensive output - consider piping to Select-Object -First to limit output.


## Outputs

Microsoft.PowerShell.Commands.ByteCollection Hexadecimal representation of file contents. .EXAMPLE PS C:\> Get-HexDump -Path "C:\temp\binaryfile.exe" Offset 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F ------ ----------------------------------------------- 00000000 4D 5A 90 00 03 00 00 00 04 00 00 00 FF FF 00 00 MZ.............. Shows hex dump of an executable file. .EXAMPLE PS C:\> hex-dump "C:\temp\data.bin" Offset 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F ------ ----------------------------------------------- 00000000 48 65 6C 6C 6F 20 57 6F 72 6C 64 21 00 Hello World!. Shows hex dump of a binary file using the alias. .EXAMPLE PS C:\> Get-HexDump -Path "C:\temp\textfile.txt" Offset 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F ------ ----------------------------------------------- 00000000 48 65 6C 6C 6F 2C 20 57 6F 72 6C 64 21 0D 0A Hello, World!.. Shows hex dump of a text file (note the CRLF line endings).


## Examples

### Example 1

`powershell
PS C:\> Get-HexDump -Path "C:\temp\binaryfile.exe"
    Offset     00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    ------     -----------------------------------------------
    00000000  4D 5A 90 00 03 00 00 00 04 00 00 00 FF FF 00 00  MZ..............

    Shows hex dump of an executable file.
``

### Example 2

`powershell
PS C:\> hex-dump "C:\temp\data.bin"
    Offset     00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    ------     -----------------------------------------------
    00000000  48 65 6C 6C 6F 20 57 6F 72 6C 64 21 00          Hello World!.

    Shows hex dump of a binary file using the alias.
``

### Example 3

`powershell
PS C:\> Get-HexDump -Path "C:\temp\textfile.txt"
    Offset     00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    ------     -----------------------------------------------
    00000000  48 65 6C 6C 6F 2C 20 57 6F 72 6C 64 21 0D 0A    Hello, World!..

    Shows hex dump of a text file (note the CRLF line endings).
``

## Notes

This function uses the built-in Format-Hex cmdlet. Large files may produce extensive output - consider piping to Select-Object -First to limit output.


## Related Links

- Format-Hex
    Get-FileSize
    Get-FileHashValue


## Aliases

This function has the following aliases:

- `hex-dump` - Shows hexadecimal dump of a file's contents.


## Source

Defined in: ..\profile.d\02-files-utilities.ps1
