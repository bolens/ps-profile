# Deploy-Netlify

## Synopsis

Deploys to Netlify.

## Description

Provides helper functions for Netlify deployments. Supports site deployment and management.

## Signature

```powershell
Deploy-Netlify
```

## Parameters

### -Action

Action to perform: deploy, status, open. Defaults to deploy.

### -ProjectPath

Path to the project directory. Defaults to current directory.

### -Production

Deploy to production environment.


## Outputs

System.String. Deployment status or command output.


## Examples

### Example 1

`powershell
Deploy-Netlify
        
        Deploys the current project to Netlify.
``

### Example 2

`powershell
Deploy-Netlify -Action "status"
        
        Shows Netlify deployment status.
``

## Source

Defined in: ..\profile.d\cloud-enhanced.ps1
