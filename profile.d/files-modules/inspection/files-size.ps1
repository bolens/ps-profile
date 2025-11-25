# ===============================================
# File size utility functions
# Get human-readable file sizes
# ===============================================

<#
.SYNOPSIS
    Initializes file size utility functions.
.DESCRIPTION
    Sets up internal functions for file size operations.
    This function is called automatically by Ensure-FileUtilities.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileUtilities-Size {
    # File size function
    Set-Item -Path Function:Global:_Get-FileSize -Value {
        param([string]$Path)
        if (-not (Test-Path -LiteralPath $Path)) {
            Write-Error "File not found: $Path"
            return
        }
        $len = (Get-Item -LiteralPath $Path).Length
        switch ($len) {
            { $_ -ge 1TB } { "{0:N2} TB" -f ($len / 1TB); break }
            { $_ -ge 1GB } { "{0:N2} GB" -f ($len / 1GB); break }
            { $_ -ge 1MB } { "{0:N2} MB" -f ($len / 1MB); break }
            { $_ -ge 1KB } { "{0:N2} KB" -f ($len / 1KB); break }
            default { "{0} bytes" -f $len }
        }
    } -Force
}

# Get file size
<#
.SYNOPSIS
    Shows human-readable file size.

.DESCRIPTION
    Displays the size of a file in human-readable format with appropriate units
    (bytes, KB, MB, GB, TB). Automatically chooses the most appropriate unit.

.PARAMETER Path
    The path to the file to check size. Must be a valid file path.

.INPUTS
    System.String
    File path as a string.

.OUTPUTS
    System.String
    Human-readable file size with unit.

.EXAMPLE
    PS C:\> Get-FileSize -Path "C:\temp\largefile.iso"
    4.25 GB

    Shows the size of a large ISO file in GB.

.EXAMPLE
    PS C:\> filesize "C:\temp\script.ps1"
    2.34 KB

    Shows the size of a PowerShell script using the alias.

.EXAMPLE
    PS C:\> Get-FileSize -Path "C:\temp\small.txt"
    145 bytes

    Shows the size of a small text file in bytes.

.EXAMPLE
    PS C:\> Get-FileSize -Path "nonexistent.txt"
    Get-FileSize : File not found: nonexistent.txt
    At line:1 char:1

    Shows error when file doesn't exist.

.NOTES
    File sizes are displayed with 2 decimal places for larger units.
    Uses the file's Length property from Get-Item.

.LINK
    Get-Item
    Get-FileHashValue
    Test-Path
#>
function Get-FileSize {
    param([string]$Path)
    if (-not $global:FileUtilitiesInitialized) { Ensure-FileUtilities }
    & "Global:_Get-FileSize" @PSBoundParameters
}
Set-Alias -Name filesize -Value Get-FileSize -ErrorAction SilentlyContinue

