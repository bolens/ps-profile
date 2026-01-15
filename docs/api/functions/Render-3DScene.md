# Render-3DScene

## Synopsis

Renders a 3D scene using Blender.

## Description

Renders a 3D scene from a Blender project file using Blender's command-line interface. Supports various output formats and rendering engines.

## Signature

```powershell
Render-3DScene
```

## Parameters

### -ProjectPath

Path to Blender project file (.blend).

### -OutputPath

Path to output rendered image.

### -Frame

Frame number to render. If not specified, renders current frame.

### -Engine

Rendering engine: 'cycles', 'eevee', 'workbench'. Defaults to 'cycles'.


## Outputs

System.String. Path to the rendered image.


## Examples

### Example 1

`powershell
Render-3DScene -ProjectPath "scene.blend" -OutputPath "render.png"
        
        Renders a Blender scene to PNG.
``

### Example 2

`powershell
Render-3DScene -ProjectPath "scene.blend" -OutputPath "render.png" -Frame 10 -Engine "eevee"
        
        Renders frame 10 using Eevee engine.
``

## Source

Defined in: ..\profile.d\3d-cad.ps1
