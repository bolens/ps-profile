# Launch-Emacs

## Synopsis

Launches Emacs editor.

## Description

Launches Emacs editor. Optionally opens files.

## Signature

```powershell
Launch-Emacs
```

## Parameters

### -Path

File path to open. Defaults to current directory.

### -NoWindow

Start Emacs in daemon mode (no window).


## Outputs

None.


## Examples

### Example 1

`powershell
Launch-Emacs
        
        Launches Emacs.
``

### Example 2

`powershell
Launch-Emacs -Path "script.ps1"
        
        Opens a file in Emacs.
``

## Source

Defined in: ..\profile.d\editors.ps1
