# re-tools.ps1

Reverse engineering and analysis tools fragment.

## Overview

This fragment provides wrapper functions for reverse engineering and binary analysis tools, including Java/Dex decompilers, .NET decompilers, PE analyzers, Android tools, and IL2CPP utilities.

## Functions

### Decompile-Java

Decompiles Java or Dex files to Java source code using jadx.

**Syntax:**

```powershell
Decompile-Java -InputFile <string> [-OutputPath <string>] [-DecompileResources] [<CommonParameters>]
```

**Parameters:**

- `-InputFile` (Required): Path to the Java/Dex file to decompile (.class, .jar, .dex, .apk)
- `-OutputPath` (Optional): Directory to save decompiled source. Defaults to current directory.
- `-DecompileResources` (Switch): Also decompile resources (for APK files).

**Examples:**

```powershell
# Decompile a Dex file
Decompile-Java -InputFile "app.dex"

# Decompile an APK file including resources
Decompile-Java -InputFile "app.apk" -DecompileResources -OutputPath ".\decompiled"
```

**Supported Tools:**

- `jadx` - Dex to Java decompiler (preferred)

**Notes:**

- Supports .class, .jar, .dex, and .apk files
- Creates output directory if it doesn't exist
- Returns path to output directory on success

---

### Decompile-DotNet

Decompiles .NET assemblies to C# or IL source code.

**Syntax:**

```powershell
Decompile-DotNet -InputFile <string> [-OutputPath <string>] [-OutputFormat <string>] [<CommonParameters>]
```

**Parameters:**

- `-InputFile` (Required): Path to the .NET assembly to decompile (.dll, .exe)
- `-OutputPath` (Optional): Directory to save decompiled source. Defaults to current directory.
- `-OutputFormat` (Optional): Output format: 'cs' (C#) or 'il' (IL). Defaults to 'cs'.

**Examples:**

```powershell
# Decompile a .NET assembly to C#
Decompile-DotNet -InputFile "app.dll"

# Decompile to IL format
Decompile-DotNet -InputFile "app.dll" -OutputFormat "il" -OutputPath ".\output"
```

**Supported Tools:**

- `dnspyex` - .NET decompiler (preferred)
- `dnspy` - .NET decompiler (fallback)

**Notes:**

- Prefers dnspyex over dnspy when both are available
- dnspy/dnspyex are primarily GUI tools; command-line support may be limited
- Returns path to output file on success

---

### Analyze-PE

Analyzes Windows PE (Portable Executable) files for metadata, imports, exports, and structure.

**Syntax:**

```powershell
Analyze-PE -InputFile <string> [-OutputPath <string>] [-Detailed] [<CommonParameters>]
```

**Parameters:**

- `-InputFile` (Required): Path to the PE file to analyze (.exe, .dll)
- `-OutputPath` (Optional): File to save analysis results.
- `-Detailed` (Switch): Show detailed analysis information.

**Examples:**

```powershell
# Analyze a PE file
Analyze-PE -InputFile "app.exe"

# Analyze and save results to file
Analyze-PE -InputFile "app.exe" -OutputPath "analysis.txt" -Detailed
```

**Supported Tools:**

- `pe-bear` - PE file analyzer (preferred, GUI tool)
- `exeinfo-pe` - PE file analyzer (fallback)
- `detect-it-easy` - File type detector (fallback, GUI tool)

**Notes:**

- Prefers pe-bear → exeinfo-pe → detect-it-easy
- pe-bear and detect-it-easy are primarily GUI tools
- Returns analysis results or path to output file

---

### Extract-AndroidApk

Extracts and decompiles Android APK files using apktool.

**Syntax:**

```powershell
Extract-AndroidApk -InputFile <string> [-OutputPath <string>] [-Decompile] [-NoResources] [<CommonParameters>]
```

**Parameters:**

- `-InputFile` (Required): Path to the APK file to extract
- `-OutputPath` (Optional): Directory to save extracted files. Defaults to current directory.
- `-Decompile` (Switch): Decompile to smali code (default: extract resources only)
- `-NoResources` (Switch): Do not extract resources

**Examples:**

```powershell
# Extract resources from an APK
Extract-AndroidApk -InputFile "app.apk"

# Extract and decompile to smali
Extract-AndroidApk -InputFile "app.apk" -Decompile -OutputPath ".\extracted"
```

**Supported Tools:**

- `apktool` - Android APK tool

**Notes:**

- By default, extracts resources only (no smali decompilation)
- Use `-Decompile` to decompile to smali code
- Use `-NoResources` to skip resource extraction
- Returns path to output directory on success

---

### Dump-IL2CPP

Dumps IL2CPP metadata from Unity games.

**Syntax:**

```powershell
Dump-IL2CPP -MetadataFile <string> -BinaryFile <string> [-OutputPath <string>] [-UnityVersion <string>] [<CommonParameters>]
```

**Parameters:**

- `-MetadataFile` (Required): Path to global-metadata.dat file
- `-BinaryFile` (Required): Path to the IL2CPP binary (GameAssembly.dll or libil2cpp.so)
- `-OutputPath` (Optional): Directory to save dumped metadata. Defaults to current directory.
- `-UnityVersion` (Optional): Unity version (for better compatibility)

**Examples:**

```powershell
# Dump IL2CPP metadata
Dump-IL2CPP -MetadataFile "global-metadata.dat" -BinaryFile "GameAssembly.dll"

# Dump with Unity version specified
Dump-IL2CPP -MetadataFile "global-metadata.dat" -BinaryFile "GameAssembly.dll" -UnityVersion "2021.3.0" -OutputPath ".\dumped"
```

**Supported Tools:**

- `il2cppdumper` - IL2CPP dumper

**Notes:**

- Requires both metadata file and binary file
- Unity version is optional but can improve compatibility
- Returns path to output directory on success

---

## Installation

Install the required tools using Scoop:

```powershell
# Java/Dex decompilation
scoop install jadx

# .NET decompilation
scoop install dnspyex
# or
scoop install dnspy

# PE analysis
scoop install pe-bear
# or
scoop install exeinfo-pe
# or
scoop install detect-it-easy

# Android tools
scoop install apktool

# IL2CPP tools
scoop install il2cppdumper
```

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions return `$null` when tools are missing
- Warning messages are displayed with installation hints
- No errors are thrown for missing tools (unless `-ErrorAction Stop` is used)

## Tool Preferences and Fallbacks

Several functions support multiple tools with preference order:

- **Decompile-DotNet**: `dnspyex` → `dnspy`
- **Analyze-PE**: `pe-bear` → `exeinfo-pe` → `detect-it-easy`

The function automatically uses the first available tool in the preference order.

## Notes

- Some tools (pe-bear, detect-it-easy, dnspy/dnspyex) are primarily GUI applications; command-line support may be limited
- Functions create output directories automatically if they don't exist
- All functions validate input file existence before processing
- Functions return appropriate paths or results on success, `$null` on failure

## See Also

- [jadx](https://github.com/skylot/jadx) - Dex to Java decompiler
- [dnspy](https://github.com/dnSpy/dnSpy) - .NET decompiler
- [pe-bear](https://github.com/hasherezade/pe-bear) - PE file analyzer
- [apktool](https://ibotpeaches.github.io/Apktool/) - Android APK tool
- [IL2CPPDumper](https://github.com/Perfare/Il2CppDumper) - IL2CPP dumper
