# ===============================================
# 02-files-utilities.ps1
# File utility functions
# ===============================================

# Ensure file utilities are loaded
<#
.SYNOPSIS
    Sets up all file utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
#>
function Ensure-FileUtilities {
    if ($global:FileUtilitiesInitialized) { return }

    # File head function
    function Global:_Get-FileHead {
        param([Parameter(Position = 0)] $Path, [Parameter(ValueFromPipeline = $true)] $InputObject, [int]$Lines = 10)

        begin {
            $collectedInput = @()
            # Handle case where first positional argument is a number (lines count)
            if ($Path -and $Path -match '^-?\d+$') {
                $numLines = [math]::Abs([int]$Path)
                if ($numLines -gt 0) {
                    $Lines = $numLines
                    $Path = $null
                }
                # If zero, treat as invalid and keep as path (will fail later)
            }
        }

        process {
            if ($Path) {
                # File mode - read from file
                Get-Content -LiteralPath $Path | Select-Object -First $Lines
                return
            }
            # Pipeline mode - collect input
            if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
                # If it's an enumerable (like an array), add each item
                foreach ($item in $InputObject) {
                    $collectedInput += $item
                }
            }
            else {
                $collectedInput += $InputObject
            }
        }

        end {
            if (-not $Path -and $collectedInput) {
                $collectedInput | Select-Object -First $Lines
            }
        }
    }

    # File tail function
    function Global:_Get-FileTail {
        param([Parameter(Position = 0)] $Path, [Parameter(ValueFromPipeline = $true)] $InputObject, [int]$Lines = 10)

        begin {
            $collectedInput = @()
            # Handle case where first positional argument is a number (lines count)
            if ($Path -and $Path -match '^-?\d+$') {
                $numLines = [math]::Abs([int]$Path)
                if ($numLines -gt 0) {
                    $Lines = $numLines
                    $Path = $null
                }
                # If zero, treat as invalid and keep as path (will fail later)
            }
        }

        process {
            if ($Path) {
                # File mode - read from file
                Get-Content -LiteralPath $Path | Select-Object -Last $Lines
                return
            }
            # Pipeline mode - collect input
            if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
                # If it's an enumerable (like an array), add each item
                foreach ($item in $InputObject) {
                    $collectedInput += $item
                }
            }
            else {
                $collectedInput += $InputObject
            }
        }

        end {
            if (-not $Path -and $collectedInput) {
                $collectedInput | Select-Object -Last $Lines
            }
        }
    }

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

    # Hex dump function
    Set-Item -Path Function:Global:_Get-HexDump -Value {
        param([string]$Path)
        Format-Hex -Path $Path
    } -Force

    # Mark as initialized
    $global:FileUtilitiesInitialized = $true
}

# Head (first 10 lines) of a file
<#
.SYNOPSIS
    Shows the first N lines of a file or pipeline input.

.DESCRIPTION
    Displays the beginning of a file or pipeline input. Defaults to 10 lines.
    Similar to the Unix 'head' command but designed for PowerShell pipelines.

.PARAMETER InputObject
    Objects to process from the pipeline.

.PARAMETER Lines
    The number of lines to display. Default is 10.

.PARAMETER fileArgs
    File paths to read from when not using pipeline input.

.INPUTS
    System.Object
    Objects from the pipeline or file paths as strings.

.OUTPUTS
    System.String
    The first N lines of the input.

.EXAMPLE
    PS C:\> 1..20 | head
    1
    2
    3
    4
    5
    6
    7
    8
    9
    10

    Shows the first 10 numbers from the pipeline.

.EXAMPLE
    PS C:\> 1..20 | head -Lines 5
    1
    2
    3
    4
    5

    Shows the first 5 numbers from the pipeline.

.EXAMPLE
    PS C:\> 1..20 | head -10
    1
    2
    3
    4
    5
    6
    7
    8
    9
    10

    Shows the first 10 numbers from the pipeline using Unix-style syntax.

.EXAMPLE
    PS C:\> head README.md
    # First 10 lines of README.md

    Shows the first 10 lines of the README.md file.

.EXAMPLE
    PS C:\> head README.md -Lines 5
    # First 5 lines of README.md

    Shows the first 5 lines of the README.md file.

.NOTES
    This function buffers all pipeline input before processing, so it may use more memory for large inputs.
    For very large files, consider using Get-Content with Select-Object directly.

.LINK
    Get-FileTail
    Get-Content
    Select-Object
#>
function Get-FileHead {
    param([Parameter(Position = 0)] $Path, [Parameter(ValueFromPipeline = $true)] $InputObject, [int]$Lines = 10)
    begin {
        $collectedInput = @()
        if (-not $global:FileUtilitiesInitialized) { Ensure-FileUtilities }
        # Handle case where first positional argument is a number (lines count)
        if ($Path -and $Path -match '^-?\d+$') {
            $numLines = [math]::Abs([int]$Path)
            if ($numLines -gt 0) {
                $Lines = $numLines
                $Path = $null
            }
            # If zero, treat as invalid and keep as path (will fail later)
        }
    }
    process {
        if ($Path) {
            # File mode - pass through to internal function
            _Get-FileHead -Path $Path -Lines $Lines
            return
        }
        # Pipeline mode - collect input
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            foreach ($item in $InputObject) {
                $collectedInput += $item
            }
        }
        else {
            $collectedInput += $InputObject
        }
    }
    end {
        if (-not $Path -and $collectedInput) {
            $collectedInput | _Get-FileHead -Lines $Lines
        }
    }
}
Set-Alias -Name head -Value Get-FileHead -ErrorAction SilentlyContinue

# Tail (last 10 lines) of a file
<#
.SYNOPSIS
    Shows the last N lines of a file or pipeline input.

.DESCRIPTION
    Displays the end of a file or pipeline input. Defaults to 10 lines.
    Similar to the Unix 'tail' command but designed for PowerShell pipelines.

.PARAMETER InputObject
    Objects to process from the pipeline.

.PARAMETER Lines
    The number of lines to display. Default is 10.

.PARAMETER fileArgs
    File paths to read from when not using pipeline input.

.INPUTS
    System.Object
    Objects from the pipeline or file paths as strings.

.OUTPUTS
    System.String
    The last N lines of the input.

.EXAMPLE
    PS C:\> 1..20 | tail
    11
    12
    13
    14
    15
    16
    17
    18
    19
    20

    Shows the last 10 numbers from the pipeline.

.EXAMPLE
    PS C:\> 1..20 | tail -Lines 5
    16
    17
    18
    19
    20

    Shows the last 5 numbers from the pipeline.

.EXAMPLE
    PS C:\> 1..20 | tail -20
    1
    2
    3
    4
    5
    6
    7
    8
    9
    10
    11
    12
    13
    14
    15
    16
    17
    18
    19
    20

    Shows all 20 numbers from the pipeline using Unix-style syntax.

.EXAMPLE
    PS C:\> tail logfile.txt
    # Last 10 lines of logfile.txt

    Shows the last 10 lines of the logfile.txt file.

.EXAMPLE
    PS C:\> tail logfile.txt -Lines 20
    # Last 20 lines of logfile.txt

    Shows the last 20 lines of the logfile.txt file.

.NOTES
    This function buffers all pipeline input before processing, so it may use more memory for large inputs.
    For very large files, consider using Get-Content with Select-Object directly.

.LINK
    Get-FileHead
    Get-Content
    Select-Object
#>
function Get-FileTail {
    param([Parameter(Position = 0)] $Path, [Parameter(ValueFromPipeline = $true)] $InputObject, [int]$Lines = 10)
    begin {
        $collectedInput = @()
        if (-not $global:FileUtilitiesInitialized) { Ensure-FileUtilities }
        # Handle case where first positional argument is a number (lines count)
        if ($Path -and $Path -match '^-?\d+$') {
            $numLines = [math]::Abs([int]$Path)
            if ($numLines -gt 0) {
                $Lines = $numLines
                $Path = $null
            }
            # If zero, treat as invalid and keep as path (will fail later)
        }
    }
    process {
        if ($Path) {
            # File mode - pass through to internal function
            _Get-FileTail -Path $Path -Lines $Lines
            return
        }
        # Pipeline mode - collect input
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            foreach ($item in $InputObject) {
                $collectedInput += $item
            }
        }
        else {
            $collectedInput += $InputObject
        }
    }
    end {
        if (-not $Path -and $collectedInput) {
            $collectedInput | _Get-FileTail -Lines $Lines
        }
    }
}
Set-Alias -Name tail -Value Get-FileTail -ErrorAction SilentlyContinue

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
    _Get-FileHashValue @PSBoundParameters
}
Set-Alias -Name file-hash -Value Get-FileHashValue -ErrorAction SilentlyContinue

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
    _Get-FileSize @PSBoundParameters
}
Set-Alias -Name filesize -Value Get-FileSize -ErrorAction SilentlyContinue

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
    _Get-HexDump @PSBoundParameters
}
Set-Alias -Name hex-dump -Value Get-HexDump -ErrorAction SilentlyContinue
