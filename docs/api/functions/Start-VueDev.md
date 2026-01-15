# Start-VueDev

## Synopsis

Starts Vue.js development server.

## Description

Wrapper for Vue CLI serve command. Prefers npx @vue/cli, falls back to globally installed vue.

## Signature

```powershell
Start-VueDev
```

## Parameters

### -Arguments

Arguments to pass to vue serve.


## Examples

### Example 1

`powershell
Start-VueDev
``

### Example 2

`powershell
Start-VueDev --port 8080
``

## Aliases

This function has the following aliases:

- `vue-serve` - Starts Vue.js development server.


## Source

Defined in: ..\profile.d\vue.ps1
