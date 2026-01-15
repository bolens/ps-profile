# Launch-Blender

## Synopsis

Launches Blender 3D modeling and animation software.

## Description

Launches Blender, a 3D modeling, animation, and rendering software. Optionally opens a project file.

## Signature

```powershell
Launch-Blender
```

## Parameters

### -ProjectPath

Optional path to Blender project file (.blend) to open.

### -Background

Run in background mode (no GUI).

### -Script

Python script to execute.


## Outputs

None.


## Examples

### Example 1

`powershell
Launch-Blender
        
        Launches Blender.
``

### Example 2

`powershell
Launch-Blender -ProjectPath "scene.blend"
        
        Launches Blender and opens a project file.
``

### Example 3

`powershell
Launch-Blender -Background -Script "render.py"
        
        Runs Blender in background mode with a Python script.
``

## Source

Defined in: ..\profile.d\3d-cad.ps1
