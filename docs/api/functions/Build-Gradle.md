# Build-Gradle

## Synopsis

Builds Java projects using Gradle.

## Description

Wrapper function for Gradle, a build automation tool for Java projects.

## Signature

```powershell
Build-Gradle
```

## Parameters

### -Arguments

Additional arguments to pass to gradle. Can be used multiple times or as an array.


## Outputs

System.String. Output from Gradle execution.


## Examples

### Example 1

`powershell
Build-Gradle
        Builds the current Gradle project.
``

### Example 2

`powershell
Build-Gradle build
        Builds the project.
``

### Example 3

`powershell
Build-Gradle test
        Runs Gradle tests.
``

## Aliases

This function has the following aliases:

- `gradle` - Builds Java projects using Gradle.


## Source

Defined in: ..\profile.d\lang-java.ps1
