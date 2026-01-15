# Set-JavaVersion

## Synopsis

Switches Java version using JAVA_HOME.

## Description

Helper function to switch Java versions by setting JAVA_HOME environment variable. This is a simple wrapper that sets JAVA_HOME to point to a specific Java installation.

## Signature

```powershell
Set-JavaVersion
```

## Parameters

### -Version

Java version to switch to (e.g., '17', '21', '11'). If not specified, displays current Java version.

### -JavaHome

Full path to Java installation directory. If not specified, attempts to find Java in common locations.


## Outputs

System.String. Current Java version information.


## Examples

### Example 1

`powershell
Set-JavaVersion -Version 17
        Switches to Java 17 (if available).
``

### Example 2

`powershell
Set-JavaVersion -JavaHome "C:\Program Files\Java\jdk-17"
        Sets JAVA_HOME to the specified path.
``

## Source

Defined in: ..\profile.d\lang-java.ps1
