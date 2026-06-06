# Grep-WithRipgrep

## Synopsis

Searches text using ripgrep with enhanced options.

## Description

Enhanced wrapper for ripgrep (rg) with line numbers, context lines, file type filtering, and case-insensitive search options.

## Signature

```powershell
Grep-WithRipgrep
```

## Parameters

### -Pattern

Text pattern to search for (regex supported).

### -Path

Directory or file to search in. Defaults to current directory.

### -FileType

File type filter (e.g., "ps1", "md", "json"). Uses ripgrep type filters.

### -CaseSensitive

Enable case-sensitive search (default: false).

### -Context

Number of context lines to show before and after matches.

### -OnlyMatching

Show only matching text, not full lines.

### -FilesWithMatches

Show only file names that contain matches.

### -Hidden

Search hidden files and directories (default: false).


## Outputs

System.String. Search results from ripgrep.


## Examples

### Example 1

`powershell
Grep-WithRipgrep -Pattern "function"
    
    Searches for "function" in all files in current directory.
``

### Example 2

`powershell
Grep-WithRipgrep -Pattern "error" -FileType "ps1" -Context 3
    
    Searches for "error" in PowerShell files with 3 lines of context.
``

### Example 3

`powershell
Grep-WithRipgrep -Pattern "TODO" -FilesWithMatches
    
    Lists only files containing "TODO".
``

## Aliases

This function has the following aliases:

- `grg` - Searches text using ripgrep with enhanced options.


## Source

Defined in: ../profile.d/cli-modules/modern-cli.ps1
