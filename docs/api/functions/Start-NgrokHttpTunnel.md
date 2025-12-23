# Start-NgrokHttpTunnel

## Synopsis

Creates an Ngrok HTTP tunnel.

## Description

Wrapper for ngrok http command to expose a local HTTP server.

## Signature

```powershell
Start-NgrokHttpTunnel
```

## Parameters

### -Port

Port number of the local HTTP server (default: 80).


## Examples

### Example 1

`powershell
Start-NgrokHttpTunnel -Port 8080
``

### Example 2

`powershell
Start-NgrokHttpTunnel -Port 3000
``

## Aliases

This function has the following aliases:

- `ngrok-http` - Creates an Ngrok HTTP tunnel.


## Source

Defined in: ..\profile.d\36-ngrok.ps1
