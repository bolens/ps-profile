# Build-Ant

## Synopsis

Builds Java projects using Apache Ant.

## Description

Wrapper function for Apache Ant, a build tool for Java projects.

## Signature

```powershell
Build-Ant
```

## Parameters

### -Arguments

Additional arguments to pass to ant. Can be used multiple times or as an array.


## Outputs

System.String. Output from Ant execution.


## Examples

### Example 1

`powershell
Build-Ant
        Builds the current Ant project.
``

### Example 2

`powershell
Build-Ant clean
        Cleans the project.
``

### Example 3

`powershell
Build-Ant test
        Runs Ant tests.
``

## Aliases

This function has the following aliases:

- `ant` - Builds Java projects using Apache Ant.


## Source

Defined in: ..\profile.d\lang-java.ps1
