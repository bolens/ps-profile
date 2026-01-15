# Remove-ComposerPackage

## Synopsis

Removes packages from Composer project.

## Description

Removes packages from composer.json. Supports --dev flag.

## Signature

```powershell
Remove-ComposerPackage
```

## Parameters

### -Packages

Package names to remove.

### -Dev

Remove from dev dependencies (--dev).


## Examples

### Example 1

`powershell
Remove-ComposerPackage monolog/monolog
    Removes monolog from production dependencies.
``

### Example 2

`powershell
Remove-ComposerPackage phpunit/phpunit -Dev
    Removes phpunit from dev dependencies.
``

## Aliases

This function has the following aliases:

- `composer-remove` - Removes packages from Composer project.


## Source

Defined in: ..\profile.d\php.ps1
