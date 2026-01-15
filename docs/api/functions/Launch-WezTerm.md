# Launch-WezTerm

## Synopsis

Launches WezTerm terminal emulator.

## Description

Launches WezTerm, a GPU-accelerated cross-platform terminal emulator. Prefers wezterm-nightly, falls back to wezterm. Optionally executes a command in the new terminal.

## Signature

```powershell
Launch-WezTerm
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
Launch-WezTerm
        
        Launches WezTerm terminal.
``

### Example 2

`powershell
Launch-WezTerm -Command "docker ps"
        
        Launches WezTerm and executes a command.
``

## Source

Defined in: ..\profile.d\terminal-enhanced.ps1
