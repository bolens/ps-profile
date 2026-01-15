# Decompile-Java

## Synopsis

Decompiles Java or Dex files using jadx.

## Description

Decompiles Java class files or Android Dex files to Java source code using jadx. Supports .class, .jar, .dex, and .apk files.

## Signature

```powershell
Decompile-Java
```

## Parameters

### -InputFile

Path to the Java/Dex file to decompile.

### -OutputPath

Directory to save decompiled source. Defaults to current directory.

### -DecompileResources

Also decompile resources (for APK files).


## Outputs

System.String. Path to the output directory.


## Examples

### Example 1

`powershell
Decompile-Java -InputFile "app.dex"
        
        Decompiles a Dex file to Java source.
``

### Example 2

`powershell
Decompile-Java -InputFile "app.apk" -DecompileResources
        
        Decompiles an APK file including resources.
``

## Source

Defined in: ..\profile.d\re-tools.ps1
