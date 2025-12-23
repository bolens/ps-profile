# Invoke-LaravelArt

## Synopsis

Executes Laravel Artisan commands (alias).

## Description

Alternative wrapper for Laravel Artisan CLI using 'art' command if available.

## Signature

```powershell
Invoke-LaravelArt
```

## Parameters

### -Arguments

Arguments to pass to artisan.


## Examples

### Example 1

`powershell
Invoke-LaravelArt --version
``

### Example 2

`powershell
Invoke-LaravelArt make:model MyModel
``

## Aliases

This function has the following aliases:

- `art` - Executes Laravel Artisan commands (alias).


## Source

Defined in: ..\profile.d\43-laravel.ps1
