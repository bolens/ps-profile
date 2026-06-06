# Find-WithFd

## Synopsis

Finds files and directories using fd with enhanced options.

## Description

Enhanced wrapper for fd (find alternative) with common search patterns, case-insensitive search, hidden files, and follow symlinks options.

## Signature

```powershell
Find-WithFd
```

## Parameters

### -Pattern

Search pattern (file name or path pattern).

### -Path

Starting directory for search. Defaults to current directory.

### -Type

File type filter: f (files), d (directories), l (symlinks).

### -Extension

File extension filter (e.g., "ps1", "md").

### -CaseSensitive

Enable case-sensitive search (default: false).

### -Hidden

Include hidden files and directories (default: false).

### -FollowSymlinks

Follow symbolic links (default: false).


## Outputs

System.String[]. Array of matching file/directory paths.


## Examples

### Example 1

`powershell
Find-WithFd -Pattern "test"
    
    Finds all files and directories containing "test" in the name.
``

### Example 2

`powershell
Find-WithFd -Pattern "*.ps1" -Type f -Extension "ps1"
    
    Finds all PowerShell script files.
``

### Example 3

`powershell
Find-WithFd -Pattern "config" -Path "C:\Users" -Hidden
    
    Finds config files including hidden ones.
``

## Aliases

This function has the following aliases:

- `ffd` - Finds files and directories using fd with enhanced options.


## Source

Defined in: ../profile.d/cli-modules/modern-cli.ps1
