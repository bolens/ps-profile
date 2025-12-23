# Invoke-Ngrok

## Synopsis

Executes Ngrok commands.

## Description

Wrapper function for Ngrok CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Ngrok
```

## Parameters

### -Arguments

Arguments to pass to ngrok.


## Examples

### Example 1

`powershell
Invoke-Ngrok version
``

### Example 2

`powershell
Invoke-Ngrok http 8080
``

## Aliases

This function has the following aliases:

- `ngrok` - Executes Ngrok commands.


## Source

Defined in: ..\profile.d\36-ngrok.ps1
