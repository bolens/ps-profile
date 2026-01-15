# Launch-Tabby

## Synopsis

Launches Tabby terminal emulator.

## Description

Launches Tabby, a modern terminal emulator with SSH and serial port support. Optionally executes a command in the new terminal.

## Signature

```powershell
Launch-Tabby
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
Launch-Tabby
        
        Launches Tabby terminal.
``

### Example 2

`powershell
Launch-Tabby -Command "npm run dev"
        
        Launches Tabby and executes a command.
``

## Source

Defined in: ..\profile.d\terminal-enhanced.ps1
