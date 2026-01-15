# Convert-3DFormat

## Synopsis

Converts 3D model between different formats using Blender.

## Description

Converts 3D model files between different formats using Blender's command-line interface. Supports many input and output formats (OBJ, STL, FBX, DAE, PLY, etc.).

## Signature

```powershell
Convert-3DFormat
```

## Parameters

### -InputFile

Path to the input 3D model file.

### -OutputFile

Path to the output 3D model file.

### -Format

Output format. If not specified, inferred from OutputFile extension.


## Outputs

System.String. Path to the output file.


## Examples

### Example 1

`powershell
Convert-3DFormat -InputFile "model.obj" -OutputFile "model.stl"
        
        Converts OBJ file to STL format.
``

### Example 2

`powershell
Convert-3DFormat -InputFile "model.fbx" -OutputFile "model.dae" -Format "dae"
        
        Converts FBX file to DAE format.
``

## Source

Defined in: ..\profile.d\3d-cad.ps1
