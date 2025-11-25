# ===============================================
# File hash utility functions
# Calculate cryptographic hashes of files
# ===============================================

<#
.SYNOPSIS
    Initializes file hash utility functions.
.DESCRIPTION
    Sets up internal functions for file hash operations.
    This function is called automatically by Ensure-FileUtilities.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileUtilities-Hash {
    # File hash function
    Set-Item -Path Function:Global:_Get-FileHashValue -Value {
        param(
            [string]$Path,
            [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
            [string]$Algorithm = 'SHA256'
        )

        if (-not (Test-Path -LiteralPath $Path)) {
            # Only show warning when not running in Pester tests
            if (-not (Get-Module -Name Pester -ErrorAction SilentlyContinue)) {
                Write-Warning "File not found: $Path"
            }
            return $null
        }

        Microsoft.PowerShell.Utility\Get-FileHash -Algorithm $Algorithm -Path $Path
    } -Force
}

# Get file hash
<#
.SYNOPSIS
    Calculates cryptographic hash of a file.

.DESCRIPTION
    Computes the hash value of a file using the specified cryptographic algorithm.
    Useful for file integrity verification and duplicate detection.

.PARAMETER Path
    The path to the file to hash. Must be a valid file path.

.PARAMETER Algorithm
    The hash algorithm to use. Valid values are MD5, SHA1, SHA256, SHA384, SHA512.
    Default is SHA256.

.INPUTS
    System.String
    File path as a string.

.OUTPUTS
    Microsoft.PowerShell.Commands.FileHashInfo
    Object containing the hash algorithm, hash value, and file path.

.EXAMPLE
    PS C:\> Get-FileHashValue -Path "C:\temp\file.txt"
    Algorithm       Hash                                                                   Path
    ---------       ----                                                                   ----
    SHA256          4A5B8C9D...                                                           C:\temp\file.txt

    Calculates SHA256 hash of file.txt.

.EXAMPLE
    PS C:\> file-hash "C:\temp\file.txt" -Algorithm MD5
    Algorithm       Hash                                                                   Path
    ---------       ----                                                                   ----
    MD5             9F8E7D6C...                                                           C:\temp\file.txt

    Calculates MD5 hash of file.txt using the alias.

.EXAMPLE
    PS C:\> Get-FileHashValue -Path "nonexistent.txt"
    WARNING: File not found: nonexistent.txt

    Shows warning when file doesn't exist.

.NOTES
    This function uses the built-in Get-FileHash cmdlet for actual hash computation.
    For large files, hash calculation may take some time.

.LINK
    Get-FileHash
    Get-FileSize
    Test-Path
#>
function Get-FileHashValue {
    param([string]$Path, [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')][string]$Algorithm = 'SHA256')
    if (-not $global:FileUtilitiesInitialized) { Ensure-FileUtilities }
    & "Global:_Get-FileHashValue" @PSBoundParameters
}
Set-Alias -Name file-hash -Value Get-FileHashValue -ErrorAction SilentlyContinue

