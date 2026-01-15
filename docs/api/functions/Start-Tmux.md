# Start-Tmux

## Synopsis

Starts a tmux terminal multiplexer session.

## Description

Starts a new tmux session or attaches to an existing one. Supports session naming and command execution.

## Signature

```powershell
Start-Tmux
```

## Parameters

### -SessionName

Name for the tmux session. If not provided, creates a new session.

### -Command

Command to execute in the new session.

### -Attach

Attach to existing session if it exists, otherwise create new one.


## Outputs

System.String. Session name or nothing.


## Examples

### Example 1

`powershell
Start-Tmux
        
        Starts a new tmux session.
``

### Example 2

`powershell
Start-Tmux -SessionName "dev" -Command "npm start"
        
        Starts a named tmux session and executes a command.
``

### Example 3

`powershell
Start-Tmux -SessionName "dev" -Attach
        
        Attaches to existing session or creates new one.
``

## Source

Defined in: ..\profile.d\terminal-enhanced.ps1
