# Deploy-Balena

## Synopsis

Deploys to Balena devices.

## Description

Provides helper functions for Balena IoT container deployments. Supports pushing applications to Balena devices.

## Signature

```powershell
Deploy-Balena
```

## Parameters

### -Action

Action to perform: push, logs, ssh, status. Defaults to push.

### -Application

Balena application name.

### -Device

Optional device UUID or name.


## Outputs

System.String. Deployment status or command output.


## Examples

### Example 1

`powershell
Deploy-Balena -Application "my-app" -Action "push"
        
        Pushes the current directory to Balena application.
``

### Example 2

`powershell
Deploy-Balena -Application "my-app" -Action "logs" -Device "device-uuid"
        
        Shows logs from a specific device.
``

## Source

Defined in: ..\profile.d\containers-enhanced.ps1
