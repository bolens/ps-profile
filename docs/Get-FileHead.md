# Get-FileHead

## Synopsis

Shows the first N lines of a file or pipeline input.

## Description

Displays the beginning of a file or pipeline input. Defaults to 10 lines. Similar to the Unix 'head' command but designed for PowerShell pipelines.

## Signature

```powershell
Get-FileHead
```

## Parameters

### -InputObject

Objects to process from the pipeline.

### -Lines

The number of lines to display. Default is 10.

### -fileArgs

File paths to read from when not using pipeline input.


## Inputs

System.Object Objects from the pipeline or file paths as strings. .OUTPUTS System.String The first N lines of the input. .EXAMPLE PS C:\> 1..20 | head 1 2 3 4 5 6 7 8 9 10 Shows the first 10 numbers from the pipeline. .EXAMPLE PS C:\> 1..20 | head -Lines 5 1 2 3 4 5 Shows the first 5 numbers from the pipeline. .EXAMPLE PS C:\> 1..20 | head -10 1 2 3 4 5 6 7 8 9 10 Shows the first 10 numbers from the pipeline using Unix-style syntax. .EXAMPLE PS C:\> head README.md # First 10 lines of README.md Shows the first 10 lines of the README.md file. .EXAMPLE PS C:\> head README.md -Lines 5 # First 5 lines of README.md Shows the first 5 lines of the README.md file. .NOTES This function buffers all pipeline input before processing, so it may use more memory for large inputs. For very large files, consider using Get-Content with Select-Object directly.


## Outputs

System.String The first N lines of the input. .EXAMPLE PS C:\> 1..20 | head 1 2 3 4 5 6 7 8 9 10 Shows the first 10 numbers from the pipeline. .EXAMPLE PS C:\> 1..20 | head -Lines 5 1 2 3 4 5 Shows the first 5 numbers from the pipeline. .EXAMPLE PS C:\> 1..20 | head -10 1 2 3 4 5 6 7 8 9 10 Shows the first 10 numbers from the pipeline using Unix-style syntax. .EXAMPLE PS C:\> head README.md # First 10 lines of README.md Shows the first 10 lines of the README.md file. .EXAMPLE PS C:\> head README.md -Lines 5 # First 5 lines of README.md Shows the first 5 lines of the README.md file.


## Examples

### Example 1

`powershell
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
``

### Example 2

`powershell
PS C:\> 1..20 | head -Lines 5
    1
    2
    3
    4
    5

    Shows the first 5 numbers from the pipeline.
``

### Example 3

`powershell
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
``

### Example 4

`powershell
PS C:\> head README.md
    # First 10 lines of README.md

    Shows the first 10 lines of the README.md file.
``

### Example 5

`powershell
PS C:\> head README.md -Lines 5
    # First 5 lines of README.md

    Shows the first 5 lines of the README.md file.
``

## Notes

This function buffers all pipeline input before processing, so it may use more memory for large inputs. For very large files, consider using Get-Content with Select-Object directly.


## Related Links

- Get-FileTail
    Get-Content
    Select-Object


## Aliases

This function has the following aliases:

- `head` - Shows the first N lines of a file or pipeline input.


## Source

Defined in: profile.d\02-files-utilities.ps1
