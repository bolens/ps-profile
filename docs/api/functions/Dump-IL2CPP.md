# Dump-IL2CPP

## Synopsis

Dumps IL2CPP metadata from Unity games.

## Description

Extracts IL2CPP metadata and type information from Unity games. Requires the game's global-metadata.dat file and the IL2CPP binary.

## Signature

```powershell
Dump-IL2CPP
```

## Parameters

### -MetadataFile

Path to global-metadata.dat file.

### -BinaryFile

Path to the IL2CPP binary (GameAssembly.dll or libil2cpp.so).

### -OutputPath

Directory to save dumped metadata. Defaults to current directory.

### -UnityVersion

Unity version (optional, for better compatibility).


## Outputs

System.String. Path to the output directory.


## Examples

### Example 1

`powershell
Dump-IL2CPP -MetadataFile "global-metadata.dat" -BinaryFile "GameAssembly.dll"
        
        Dumps IL2CPP metadata from a Unity game.
``

## Source

Defined in: ..\profile.d\re-tools.ps1
