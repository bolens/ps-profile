# Remove-SwiftPackage

## Synopsis

Removes Swift package dependencies.

## Description

Note: Swift Package Manager dependencies are removed by editing Package.swift. This function provides guidance.

## Signature

```powershell
Remove-SwiftPackage
```

## Parameters

### -URL

Package repository URL to remove.


## Examples

### Example 1

`powershell
Remove-SwiftPackage -URL https://github.com/apple/swift-algorithms.git
        Provides instructions for removing Swift Algorithms package.
``

## Aliases

This function has the following aliases:

- `swift-remove` - Removes Swift package dependencies.


## Source

Defined in: ..\profile.d\swift.ps1
