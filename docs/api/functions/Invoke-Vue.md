# Invoke-Vue

## Synopsis

Executes Vue CLI commands.

## Description

Wrapper function for Vue CLI that checks for command availability before execution. Prefers npx @vue/cli, falls back to globally installed vue.

## Signature

```powershell
Invoke-Vue
```

## Parameters

### -Arguments

Arguments to pass to Vue CLI.


## Examples

### Example 1

`powershell
Invoke-Vue --version
``

### Example 2

`powershell
Invoke-Vue create my-app
``

## Aliases

This function has the following aliases:

- `vue` - Executes Vue CLI commands.


## Source

Defined in: ..\profile.d\48-vue.ps1
