# Get-FileTail

## Synopsis

Shows the last N lines of a file or pipeline input.

## Description

Displays the end of a file or pipeline input. Defaults to 10 lines. Similar to the Unix 'tail' command but designed for PowerShell pipelines.

## Signature

```powershell
Get-FileTail
```

## Parameters

### -InputObject

Objects to process from the pipeline.

### -Lines

The number of lines to display. Default is 10.

### -fileArgs

File paths to read from when not using pipeline input.


## Inputs

System.Object Objects from the pipeline or file paths as strings. .OUTPUTS System.String The last N lines of the input. .EXAMPLE PS C:\> 1..20 | tail 11 12 13 14 15 16 17 18 19 20 Shows the last 10 numbers from the pipeline. .EXAMPLE PS C:\> 1..20 | tail -Lines 5 16 17 18 19 20 Shows the last 5 numbers from the pipeline. .EXAMPLE PS C:\> 1..20 | tail -20 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 Shows all 20 numbers from the pipeline using Unix-style syntax. .EXAMPLE PS C:\> tail logfile.txt # Last 10 lines of logfile.txt Shows the last 10 lines of the logfile.txt file. .EXAMPLE PS C:\> tail logfile.txt -Lines 20 # Last 20 lines of logfile.txt Shows the last 20 lines of the logfile.txt file. .NOTES This function buffers all pipeline input before processing, so it may use more memory for large inputs. For very large files, consider using Get-Content with Select-Object directly.


## Outputs

System.String The last N lines of the input. .EXAMPLE PS C:\> 1..20 | tail 11 12 13 14 15 16 17 18 19 20 Shows the last 10 numbers from the pipeline. .EXAMPLE PS C:\> 1..20 | tail -Lines 5 16 17 18 19 20 Shows the last 5 numbers from the pipeline. .EXAMPLE PS C:\> 1..20 | tail -20 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 Shows all 20 numbers from the pipeline using Unix-style syntax. .EXAMPLE PS C:\> tail logfile.txt # Last 10 lines of logfile.txt Shows the last 10 lines of the logfile.txt file. .EXAMPLE PS C:\> tail logfile.txt -Lines 20 # Last 20 lines of logfile.txt Shows the last 20 lines of the logfile.txt file.


## Examples

### Example 1

`powershell
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
``

### Example 2

`powershell
PS C:\> 1..20 | tail -Lines 5
    16
    17
    18
    19
    20

    Shows the last 5 numbers from the pipeline.
``

### Example 3

`powershell
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
``

### Example 4

`powershell
PS C:\> tail logfile.txt
    # Last 10 lines of logfile.txt

    Shows the last 10 lines of the logfile.txt file.
``

### Example 5

`powershell
PS C:\> tail logfile.txt -Lines 20
    # Last 20 lines of logfile.txt

    Shows the last 20 lines of the logfile.txt file.
``

## Notes

This function buffers all pipeline input before processing, so it may use more memory for large inputs. For very large files, consider using Get-Content with Select-Object directly.


## Related Links

- Get-FileHead
    Get-Content
    Select-Object


## Aliases

This function has the following aliases:

- `tail` - Shows the last N lines of a file or pipeline input.


## Source

Defined in: profile.d\02-files-utilities.ps1
