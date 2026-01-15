# Build-GodotProject

## Synopsis

Builds a Godot project.

## Description

Builds a Godot project using the Godot command-line interface. Supports export presets and platform targets.

## Signature

```powershell
Build-GodotProject
```

## Parameters

### -ProjectPath

Path to Godot project directory.

### -ExportPreset

Export preset name to use.

### -OutputPath

Output directory for the build. Defaults to project directory.

### -Platform

Target platform (e.g., 'windows', 'linux', 'macos', 'android', 'ios').


## Outputs

System.String. Path to the built project or output directory.


## Examples

### Example 1

`powershell
Build-GodotProject -ProjectPath "C:\Projects\MyGame"
        
        Builds a Godot project.
``

### Example 2

`powershell
Build-GodotProject -ProjectPath "C:\Projects\MyGame" -ExportPreset "Windows Desktop"
        
        Builds a Godot project using a specific export preset.
``

## Source

Defined in: ..\profile.d\game-dev.ps1
