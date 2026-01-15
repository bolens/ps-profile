# Install-RubyDevKit

## Synopsis

Installs MSYS2 development tools using Ruby Installer Development Kit.

## Description

Runs 'ridk install' to install MSYS2 development tools needed for building native Ruby gems on Windows. This is typically required after installing Ruby from Scoop to enable compilation of native extensions.

## Signature

```powershell
Install-RubyDevKit
```

## Parameters

### -Components

Optional components to install. If not specified, runs 'ridk install' which will prompt for component selection.


## Examples

### Example 1

`powershell
Install-RubyDevKit
            Installs MSYS2 development tools (will prompt for component selection).
``

### Example 2

`powershell
Install-RubyDevKit -Components 1,2,3
            Installs specific MSYS2 components.
``

## Notes

This command is only available on Windows when Ruby is installed via Scoop. After installing Ruby with 'scoop install ruby', run this command to set up the development environment for building native gems.


## Aliases

This function has the following aliases:

- `ridk-install` - Installs MSYS2 development tools using Ruby Installer Development Kit.
- `ruby-devkit-install` - Installs MSYS2 development tools using Ruby Installer Development Kit.


## Source

Defined in: ..\profile.d\gem.ps1
