# Add-MavenDependency

## Synopsis

Adds Maven dependencies to project.

## Description

Adds dependencies to pom.xml using mvn dependency:add. Requires the versions-maven-plugin or manual pom.xml editing.

## Signature

```powershell
Add-MavenDependency
```

## Parameters

### -GroupId

Maven group ID.

### -ArtifactId

Maven artifact ID.

### -Version

Dependency version.

### -Scope

Dependency scope (compile, test, provided, runtime, system).


## Examples

### Example 1

`powershell
Add-MavenDependency -GroupId org.springframework -ArtifactId spring-core -Version 6.0.0
        Adds Spring Core dependency.
``

## Aliases

This function has the following aliases:

- `maven-add` - Adds Maven dependencies to project.


## Source

Defined in: ..\profile.d\maven.ps1
