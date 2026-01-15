# Deploy-Vercel

## Synopsis

Deploys to Vercel.

## Description

Provides helper functions for Vercel deployments. Supports project deployment and management.

## Signature

```powershell
Deploy-Vercel
```

## Parameters

### -Action

Action to perform: deploy, list, remove. Defaults to deploy.

### -ProjectPath

Path to the project directory. Defaults to current directory.

### -Production

Deploy to production environment.


## Outputs

System.String. Deployment status or command output.


## Examples

### Example 1

`powershell
Deploy-Vercel
        
        Deploys the current project to Vercel.
``

### Example 2

`powershell
Deploy-Vercel -Production
        
        Deploys to production environment.
``

## Source

Defined in: ..\profile.d\cloud-enhanced.ps1
