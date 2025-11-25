# ===============================================
# File hex dump utility functions
# Display hexadecimal representation of files
# ===============================================

<#
.SYNOPSIS
    Initializes file hex dump utility functions.
.DESCRIPTION
    Sets up internal functions for hex dump operations.
    This function is called automatically by Ensure-FileUtilities.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileUtilities-HexDump {
    # Hex dump function
    Set-Item -Path Function:Global:_Get-HexDump -Value {
        param([string]$Path)
        Format-Hex -Path $Path
    } -Force
}

# Display hex dump of file
<#
.SYNOPSIS
    Shows hexadecimal dump of a file's contents.

.DESCRIPTION
    Displays the contents of a file in hexadecimal format with ASCII representation.
    Useful for examining binary files, debugging file formats, or low-level file analysis.

.PARAMETER Path
    The path to the file to dump. Must be a valid file path.

.INPUTS
    System.String
    File path as a string.

.OUTPUTS
    Microsoft.PowerShell.Commands.ByteCollection
    Hexadecimal representation of file contents.

.EXAMPLE
    PS C:\> Get-HexDump -Path "C:\temp\binaryfile.exe"
    Offset     00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    ------     -----------------------------------------------
    00000000  4D 5A 90 00 03 00 00 00 04 00 00 00 FF FF 00 00  MZ..............

    Shows hex dump of an executable file.

.EXAMPLE
    PS C:\> hex-dump "C:\temp\data.bin"
    Offset     00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    ------     -----------------------------------------------
    00000000  48 65 6C 6C 6F 20 57 6F 72 6C 64 21 00          Hello World!.

    Shows hex dump of a binary file using the alias.

.EXAMPLE
    PS C:\> Get-HexDump -Path "C:\temp\textfile.txt"
    Offset     00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    ------     -----------------------------------------------
    00000000  48 65 6C 6C 6F 2C 20 57 6F 72 6C 64 21 0D 0A    Hello, World!..

    Shows hex dump of a text file (note the CRLF line endings).

.NOTES
    This function uses the built-in Format-Hex cmdlet.
    Large files may produce extensive output - consider piping to Select-Object -First to limit output.

.LINK
    Format-Hex
    Get-FileSize
    Get-FileHashValue
#>
function Get-HexDump {
    param([string]$Path)
    if (-not $global:FileUtilitiesInitialized) { Ensure-FileUtilities }
    & "Global:_Get-HexDump" @PSBoundParameters
}
Set-Alias -Name hex-dump -Value Get-HexDump -ErrorAction SilentlyContinue

