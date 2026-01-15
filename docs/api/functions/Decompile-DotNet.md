# Decompile-DotNet

## Synopsis

Decompiles .NET assemblies using dnspy or dnspyex.

## Description

Decompiles .NET assemblies (.dll, .exe) to C# source code. Prefers dnspyex if available, falls back to dnspy.

## Signature

```powershell
Decompile-DotNet
```

## Parameters

### -InputFile

Path to the .NET assembly to decompile.

### -OutputPath

Directory to save decompiled source. Defaults to current directory.

### -OutputFormat

Output format: 'cs' (C#) or 'il' (IL). Defaults to 'cs'.


## Outputs

System.String. Path to the output file.


## Examples

### Example 1

`powershell
Decompile-DotNet -InputFile "app.dll"
        
        Decompiles a .NET assembly to C# source.
``

## Source

Defined in: ..\profile.d\re-tools.ps1
