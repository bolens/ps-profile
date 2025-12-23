# Invoke-Composer

## Synopsis

Executes Composer commands.

## Description

Wrapper function for Composer that checks for command availability before execution.

## Signature

```powershell
Invoke-Composer
```

## Parameters

### -Arguments

Arguments to pass to composer.


## Examples

### Example 1

`powershell
Invoke-Composer --version
``

### Example 2

`powershell
Invoke-Composer install
``

## Aliases

This function has the following aliases:

- `composer` - Executes Composer commands.


## Source

Defined in: ..\profile.d\42-php.ps1
