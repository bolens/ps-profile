# New-VueApp

## Synopsis

Creates a new Vue.js project.

## Description

Wrapper for Vue CLI create command. Prefers npx @vue/cli, falls back to globally installed vue.

## Signature

```powershell
New-VueApp
```

## Parameters

### -Arguments

Arguments to pass to vue create.


## Examples

### Example 1

`powershell
New-VueApp my-app
``

### Example 2

`powershell
New-VueApp my-app --default
``

## Aliases

This function has the following aliases:

- `vue-create` - Creates a new Vue.js project.


## Source

Defined in: ..\profile.d\48-vue.ps1
