# Start-HttpToolkit

## Synopsis

Starts HTTP Toolkit proxy server.

## Description

Launches HTTP Toolkit, an HTTP debugging proxy that intercepts and inspects HTTP/HTTPS traffic. Useful for debugging API calls, inspecting requests/responses, and testing applications.

## Signature

```powershell
Start-HttpToolkit
```

## Parameters

### -Port

Port number for the proxy server. Defaults to 8000 if not specified.

### -Passthrough

If specified, starts the proxy in passthrough mode (does not intercept traffic).


## Outputs

System.Diagnostics.Process. Process object for the HTTP Toolkit proxy.


## Examples

### Example 1

`powershell
Start-HttpToolkit
        Starts HTTP Toolkit on the default port (8000).
``

### Example 2

`powershell
Start-HttpToolkit -Port 9000
        Starts HTTP Toolkit on port 9000.
``

## Aliases

This function has the following aliases:

- `httptoolkit` - Starts HTTP Toolkit proxy server.


## Source

Defined in: ..\profile.d\api-tools.ps1
