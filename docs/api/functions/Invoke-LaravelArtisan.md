# Invoke-LaravelArtisan

## Synopsis

Executes Laravel Artisan commands.

## Description

Wrapper function for Laravel Artisan CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-LaravelArtisan
```

## Parameters

### -Arguments

Arguments to pass to artisan.


## Examples

### Example 1

`powershell
Invoke-LaravelArtisan --version
``

### Example 2

`powershell
Invoke-LaravelArtisan make:controller MyController
``

## Aliases

This function has the following aliases:

- `artisan` - Executes Laravel Artisan commands.


## Source

Defined in: ..\profile.d\43-laravel.ps1
