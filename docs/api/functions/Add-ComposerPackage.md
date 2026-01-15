# Add-ComposerPackage

## Synopsis

Adds packages to Composer project.

## Description

Adds packages to composer.json. Supports --dev flag.

## Signature

```powershell
Add-ComposerPackage
```

## Parameters

### -Packages

Package names to add.

### -Dev

Add as dev dependency (--dev).


## Examples

### Example 1

`powershell
Add-ComposerPackage monolog/monolog
    Adds monolog as a production dependency.
``

### Example 2

`powershell
Add-ComposerPackage phpunit/phpunit -Dev
    Adds phpunit as a dev dependency.
``

## Aliases

This function has the following aliases:

- `composer-add` - Adds packages to Composer project.
- `composer-require` - Adds packages to Composer project.


## Source

Defined in: ..\profile.d\php.ps1
