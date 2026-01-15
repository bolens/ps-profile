# Launch-Tiled

## Synopsis

Launches Tiled tile map editor.

## Description

Launches Tiled, a tile map editor for creating game levels and maps. Supports various tile map formats.

## Signature

```powershell
Launch-Tiled
```

## Parameters

### -ProjectPath

Optional path to map file to open.


## Outputs

None.


## Examples

### Example 1

`powershell
Launch-Tiled
        
        Launches Tiled.
``

### Example 2

`powershell
Launch-Tiled -ProjectPath "map.tmx"
        
        Launches Tiled and opens a map file.
``

## Source

Defined in: ..\profile.d\game-dev.ps1
