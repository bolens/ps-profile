# Launch-Godot

## Synopsis

Launches Godot game engine.

## Description

Launches Godot game engine editor. Optionally opens a project.

## Signature

```powershell
Launch-Godot
```

## Parameters

### -ProjectPath

Optional path to Godot project directory to open.

### -Headless

Run in headless mode (no GUI).


## Outputs

None.


## Examples

### Example 1

`powershell
Launch-Godot
        
        Launches Godot editor.
``

### Example 2

`powershell
Launch-Godot -ProjectPath "C:\Projects\MyGame"
        
        Launches Godot and opens a project.
``

## Source

Defined in: ..\profile.d\game-dev.ps1
