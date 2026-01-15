# Launch-Kitty

## Synopsis

Launches Kitty terminal emulator.

## Description

Launches Kitty, a fast, feature-rich terminal emulator. Optionally executes a command in the new terminal.

## Signature

```powershell
Launch-Kitty
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
Launch-Kitty
        
        Launches Kitty terminal.
``

### Example 2

`powershell
Launch-Kitty -Command "npm start"
        
        Launches Kitty and executes a command.
``

## Source

Defined in: ..\profile.d\terminal-enhanced.ps1
