# Launch-FreeCAD

## Synopsis

Launches FreeCAD parametric CAD software.

## Description

Launches FreeCAD, a parametric 3D CAD modeler. Optionally opens a project file.

## Signature

```powershell
Launch-FreeCAD
```

## Parameters

### -ProjectPath

Optional path to FreeCAD project file (.FCStd) to open.


## Outputs

None.


## Examples

### Example 1

`powershell
Launch-FreeCAD
        
        Launches FreeCAD.
``

### Example 2

`powershell
Launch-FreeCAD -ProjectPath "model.FCStd"
        
        Launches FreeCAD and opens a project file.
``

## Source

Defined in: ..\profile.d\3d-cad.ps1
