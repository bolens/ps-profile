# Start-CloudflareTunnel

## Synopsis

Starts a Cloudflare tunnel using cloudflared.

## Description

Creates a secure tunnel to expose local services through Cloudflare. Supports HTTP, TCP, and other tunnel types.

## Signature

```powershell
Start-CloudflareTunnel
```

## Parameters

### -Url

Local URL or service to tunnel (e.g., http://localhost:8080).

### -Hostname

Optional Cloudflare hostname for the tunnel.

### -Protocol

Tunnel protocol: http, tcp, ssh, rdp. Defaults to http.


## Examples

### Example 1

`powershell
Start-CloudflareTunnel -Url "http://localhost:8080"
        
        Creates an HTTP tunnel to the local service.
``

### Example 2

`powershell
Start-CloudflareTunnel -Url "tcp://localhost:22" -Protocol "ssh"
        
        Creates an SSH tunnel.
``

## Source

Defined in: ..\profile.d\network-analysis.ps1
