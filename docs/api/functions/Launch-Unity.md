# Launch-Unity

## Synopsis

Launches Unity Hub or Unity Editor.

## Description

Launches Unity Hub (preferred) or Unity Editor. Unity Hub is the recommended way to manage Unity projects and versions.

## Signature

```powershell
Launch-Unity
```

## Parameters

### -ProjectPath

Optional path to Unity project to open.


## Outputs

None.


## Examples

### Example 1

`powershell
Launch-Unity
        
        Launches Unity Hub.
``

### Example 2

`powershell
Launch-Unity -ProjectPath "C:\Projects\MyGame"
        
        Launches Unity and opens a project.
``

## Source

Defined in: ..\profile.d\game-dev.ps1
