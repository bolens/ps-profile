# Launch-OpenSCAD

## Synopsis

Launches OpenSCAD programmatic CAD software.

## Description

Launches OpenSCAD, a programmatic 3D CAD modeler. Optionally opens a script file.

## Signature

```powershell
Launch-OpenSCAD
```

## Parameters

### -ScriptPath

Optional path to OpenSCAD script file (.scad) to open.

### -OutputPath

Optional output path for rendered model.

### -Format

Output format: 'stl', 'off', 'amf', '3mf', 'csg', 'dxf', 'svg', 'png', 'pdf'. Defaults to 'stl'.


## Outputs

System.String. Path to output file if rendered, otherwise nothing.


## Examples

### Example 1

`powershell
Launch-OpenSCAD
        
        Launches OpenSCAD.
``

### Example 2

`powershell
Launch-OpenSCAD -ScriptPath "model.scad"
        
        Launches OpenSCAD and opens a script file.
``

### Example 3

`powershell
Launch-OpenSCAD -ScriptPath "model.scad" -OutputPath "model.stl" -Format "stl"
        
        Launches OpenSCAD, opens a script, and renders to STL.
``

## Source

Defined in: ..\profile.d\3d-cad.ps1
