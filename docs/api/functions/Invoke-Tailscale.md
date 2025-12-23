# Invoke-Tailscale

## Synopsis

Executes Tailscale commands.

## Description

Wrapper function for Tailscale CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Tailscale
```

## Parameters

### -Arguments

Arguments to pass to tailscale.


## Examples

### Example 1

`powershell
Invoke-Tailscale status
``

### Example 2

`powershell
Invoke-Tailscale ping hostname
``

## Aliases

This function has the following aliases:

- `tailscale` - Gets Tailscale connection status.


## Source

Defined in: ..\profile.d\40-tailscale.ps1
