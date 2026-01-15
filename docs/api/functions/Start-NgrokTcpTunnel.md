# Start-NgrokTcpTunnel

## Synopsis

Creates an Ngrok TCP tunnel.

## Description

Wrapper for ngrok tcp command to expose a local TCP service.

## Signature

```powershell
Start-NgrokTcpTunnel
```

## Parameters

### -Port

Port number of the local TCP service.


## Examples

### Example 1

`powershell
Start-NgrokTcpTunnel -Port 22
``

### Example 2

`powershell
Start-NgrokTcpTunnel -Port 3306
``

## Aliases

This function has the following aliases:

- `ngrok-tcp` - Creates an Ngrok TCP tunnel.


## Source

Defined in: ..\profile.d\ngrok.ps1
