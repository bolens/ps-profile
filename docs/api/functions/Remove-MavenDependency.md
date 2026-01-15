# Remove-MavenDependency

## Synopsis

Removes Maven dependencies from project.

## Description

Removes dependencies from pom.xml using mvn dependency:remove.

## Signature

```powershell
Remove-MavenDependency
```

## Parameters

### -GroupId

Maven group ID.

### -ArtifactId

Maven artifact ID.


## Examples

### Example 1

`powershell
Remove-MavenDependency -GroupId org.springframework -ArtifactId spring-core
        Removes Spring Core dependency.
``

## Aliases

This function has the following aliases:

- `maven-remove` - Removes Maven dependencies from project.


## Source

Defined in: ..\profile.d\maven.ps1
