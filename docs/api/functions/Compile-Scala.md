# Compile-Scala

## Synopsis

Compiles Scala code.

## Description

Wrapper function for the Scala compiler (scalac).

## Signature

```powershell
Compile-Scala
```

## Parameters

### -Arguments

Additional arguments to pass to scalac. Can be used multiple times or as an array.


## Outputs

System.String. Output from Scala compiler execution.


## Examples

### Example 1

`powershell
Compile-Scala Main.scala
        Compiles Main.scala.
``

### Example 2

`powershell
Compile-Scala -d classes Main.scala
        Compiles to a specific output directory.
``

## Aliases

This function has the following aliases:

- `scalac` - Compiles Scala code.


## Source

Defined in: ..\profile.d\lang-java.ps1
