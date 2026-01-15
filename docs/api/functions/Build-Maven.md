# Build-Maven

## Synopsis

Builds Java projects using Maven.

## Description

Wrapper function for Maven, a build automation tool for Java projects.

## Signature

```powershell
Build-Maven
```

## Parameters

### -Arguments

Additional arguments to pass to mvn. Can be used multiple times or as an array.


## Outputs

System.String. Output from Maven execution.


## Examples

### Example 1

`powershell
Build-Maven
        Builds the current Maven project.
``

### Example 2

`powershell
Build-Maven clean install
        Cleans and installs the project.
``

### Example 3

`powershell
Build-Maven test
        Runs Maven tests.
``

## Aliases

This function has the following aliases:

- `mvn` - Builds Java projects using Maven.


## Source

Defined in: ..\profile.d\lang-java.ps1
