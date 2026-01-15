# Remove-GradleDependency

## Synopsis

Removes Gradle dependencies from project.

## Description

Note: Gradle doesn't have a direct CLI command to remove dependencies. This function provides guidance. Dependencies are typically removed manually from build.gradle.

## Signature

```powershell
Remove-GradleDependency
```

## Parameters

### -Dependency

Dependency notation to remove.


## Examples

### Example 1

`powershell
Remove-GradleDependency 'org.springframework:spring-core:6.0.0'
        Provides instructions for removing Spring Core dependency.
``

## Aliases

This function has the following aliases:

- `gradle-remove` - Removes Gradle dependencies from project.


## Source

Defined in: ..\profile.d\gradle.ps1
