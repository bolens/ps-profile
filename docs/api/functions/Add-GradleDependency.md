# Add-GradleDependency

## Synopsis

Adds Gradle dependencies to project.

## Description

Note: Gradle doesn't have a direct CLI command to add dependencies. This function provides guidance. Dependencies are typically added manually to build.gradle.

## Signature

```powershell
Add-GradleDependency
```

## Parameters

### -Configuration

Configuration name (implementation, testImplementation, etc.).

### -Dependency

Dependency notation (e.g., 'org.springframework:spring-core:6.0.0').


## Examples

### Example 1

`powershell
Add-GradleDependency -Configuration implementation -Dependency 'org.springframework:spring-core:6.0.0'
        Provides instructions for adding Spring Core dependency.
``

## Aliases

This function has the following aliases:

- `gradle-add` - Adds Gradle dependencies to project.


## Source

Defined in: ..\profile.d\gradle.ps1
