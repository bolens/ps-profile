# Extract-AndroidApk

## Synopsis

Extracts and decompiles Android APK files.

## Description

Extracts Android APK files using apktool. Can extract resources, decompile to smali, or both.

## Signature

```powershell
Extract-AndroidApk
```

## Parameters

### -InputFile

Path to the APK file to extract.

### -OutputPath

Directory to save extracted files. Defaults to current directory.

### -Decompile

Decompile to smali code (default: extract resources only).

### -NoResources

Do not extract resources.


## Outputs

System.String. Path to the output directory.


## Examples

### Example 1

`powershell
Extract-AndroidApk -InputFile "app.apk"
        
        Extracts resources from an APK file.
``

### Example 2

`powershell
Extract-AndroidApk -InputFile "app.apk" -Decompile
        
        Extracts and decompiles an APK file to smali.
``

## Source

Defined in: ..\profile.d\re-tools.ps1
