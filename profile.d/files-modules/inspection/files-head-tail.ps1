# ===============================================
# File head and tail utility functions
# Get first/last N lines of files or pipeline input
# ===============================================

<#
.SYNOPSIS
    Initializes file head and tail utility functions.
.DESCRIPTION
    Sets up internal functions for head and tail operations.
    This function is called automatically by Ensure-FileUtilities.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileUtilities-HeadTail {
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
            & "Global:_Get-FileHead" -Path $Path -Lines $Lines
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
            $collectedInput | & "Global:_Get-FileHead" -Lines $Lines
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
            & "Global:_Get-FileTail" -Path $Path -Lines $Lines
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
            $collectedInput | & "Global:_Get-FileTail" -Lines $Lines
        }
    }
}
Set-Alias -Name tail -Value Get-FileTail -ErrorAction SilentlyContinue

