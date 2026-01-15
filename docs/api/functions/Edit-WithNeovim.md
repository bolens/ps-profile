# Edit-WithNeovim

## Synopsis

Opens files in Neovim editor.

## Description

Opens files in Neovim. Prefers neovim-nightly, falls back to neovim. Can use GUI version (neovim-qt) if available.

## Signature

```powershell
Edit-WithNeovim
```

## Parameters

### -Path

File path to open. Defaults to current directory.

### -UseGui

Use GUI version (neovim-qt) if available.


## Outputs

None.


## Examples

### Example 1

`powershell
Edit-WithNeovim
        
        Opens Neovim in current directory.
``

### Example 2

`powershell
Edit-WithNeovim -Path "script.ps1"
        
        Opens a file in Neovim.
``

### Example 3

`powershell
Edit-WithNeovim -Path "script.ps1" -UseGui
        
        Opens a file in Neovim GUI.
``

## Source

Defined in: ..\profile.d\editors.ps1
