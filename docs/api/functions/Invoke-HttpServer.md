# Invoke-HttpServer

## Synopsis

Starts HTTP server.

## Description

Wrapper for http-server command. Uses globally installed http-server if available, otherwise falls back to npx.

## Signature

```powershell
Invoke-HttpServer
```

## Parameters

### -Arguments

Arguments to pass to http-server.


## Examples

### Example 1

```powershell
Invoke-HttpServer -p 8080
```

## Aliases

This function has the following aliases:

- `http-server` - Starts HTTP server.


## Source

Defined in: ../profile.d/dev-tools-modules/build/build-tools.ps1
