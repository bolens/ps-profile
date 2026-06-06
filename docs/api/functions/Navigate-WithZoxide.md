# Navigate-WithZoxide

## Synopsis

Navigates to directories using zoxide's smart matching.

## Description

Enhanced wrapper for zoxide (smart cd) that provides intelligent directory navigation based on usage frequency and fuzzy matching.

## Signature

```powershell
Navigate-WithZoxide
```

## Parameters

### -Query

Directory name or path to navigate to. Can be partial match.

### -Interactive

Use interactive mode to select from multiple matches.

### -Add

Add current directory to zoxide database.

### -Remove

Remove directory from zoxide database.

### -QueryAll

Query all directories in database.


## Outputs

System.String. Path navigated to, or null if navigation failed.


## Examples

### Example 1

`powershell
Navigate-WithZoxide -Query "Documents"
    
    Navigates to the most frequently used directory matching "Documents".
``

### Example 2

`powershell
Navigate-WithZoxide -Query "PowerShell" -Interactive
    
    Shows interactive menu if multiple matches found.
``

### Example 3

`powershell
Navigate-WithZoxide -Add
    
    Adds current directory to zoxide database.
``

## Aliases

This function has the following aliases:

- `z` - Navigates to directories using zoxide's smart matching.


## Source

Defined in: ../profile.d/cli-modules/modern-cli.ps1
