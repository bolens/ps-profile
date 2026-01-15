# Launch-Alacritty

## Synopsis

Launches Alacritty terminal emulator.

## Description

Launches Alacritty, a fast, cross-platform terminal emulator. Optionally executes a command in the new terminal.

## Signature

```powershell
Launch-Alacritty
```

## Parameters

### -Command

Command to execute in the new terminal.

### -WorkingDirectory

Working directory for the new terminal.


## Outputs

None.


## Examples

### Example 1

`powershell
Launch-Alacritty
        
        Launches Alacritty terminal.
``

### Example 2

`powershell
Launch-Alacritty -Command "git status"
        
        Launches Alacritty and executes a command.
``

## Source

Defined in: ..\profile.d\terminal-enhanced.ps1
