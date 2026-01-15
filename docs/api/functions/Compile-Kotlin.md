# Compile-Kotlin

## Synopsis

Compiles Kotlin code.

## Description

Wrapper function for the Kotlin compiler (kotlinc).

## Signature

```powershell
Compile-Kotlin
```

## Parameters

### -Arguments

Additional arguments to pass to kotlinc. Can be used multiple times or as an array.


## Outputs

System.String. Output from Kotlin compiler execution.


## Examples

### Example 1

`powershell
Compile-Kotlin Main.kt
        Compiles Main.kt.
``

### Example 2

`powershell
Compile-Kotlin -include-runtime -d app.jar Main.kt
        Compiles with runtime included into a JAR.
``

## Aliases

This function has the following aliases:

- `kotlinc` - Compiles Kotlin code.


## Source

Defined in: ..\profile.d\lang-java.ps1
