# Add-DartPackage

## Synopsis

Adds packages to Dart project.

## Description

Adds packages to pubspec.yaml. Supports --dev flag.

## Signature

```powershell
Add-DartPackage
```

## Parameters

### -Packages

Package names to add.

### -Dev

Add as dev dependency (--dev).


## Examples

### Example 1

`powershell
Add-DartPackage http
        Adds http as a production dependency.
``

### Example 2

`powershell
Add-DartPackage build_runner -Dev
        Adds build_runner as a dev dependency.
``

## Aliases

This function has the following aliases:

- `dart-add` - Adds packages to Dart project.


## Source

Defined in: ..\profile.d\dart.ps1
