# Add-FlutterPackage

## Synopsis

Adds packages to Flutter project.

## Description

Adds packages to pubspec.yaml. Supports --dev flag.

## Signature

```powershell
Add-FlutterPackage
```

## Parameters

### -Packages

Package names to add.

### -Dev

Add as dev dependency (--dev).


## Examples

### Example 1

`powershell
Add-FlutterPackage http
        Adds http as a production dependency.
``

### Example 2

`powershell
Add-FlutterPackage flutter_test -Dev
        Adds flutter_test as a dev dependency.
``

## Aliases

This function has the following aliases:

- `flutter-add` - Adds packages to Flutter project.


## Source

Defined in: ..\profile.d\dart.ps1
