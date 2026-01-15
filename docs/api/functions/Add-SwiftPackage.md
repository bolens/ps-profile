# Add-SwiftPackage

## Synopsis

Adds Swift package dependencies.

## Description

Note: Swift Package Manager dependencies are typically added via Xcode or by editing Package.swift. This function provides guidance for manual addition.

## Signature

```powershell
Add-SwiftPackage
```

## Parameters

### -URL

Package repository URL.

### -Version

Package version requirement.


## Examples

### Example 1

`powershell
Add-SwiftPackage -URL https://github.com/apple/swift-algorithms.git -Version '1.0.0'
        Provides instructions for adding Swift Algorithms package.
``

## Aliases

This function has the following aliases:

- `swift-add` - Adds Swift package dependencies.


## Source

Defined in: ..\profile.d\swift.ps1
