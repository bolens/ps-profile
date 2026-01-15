# Deploy-Heroku

## Synopsis

Deploys to Heroku.

## Description

Provides helper functions for Heroku deployments. Supports git-based deployments and direct app management.

## Signature

```powershell
Deploy-Heroku
```

## Parameters

### -AppName

Heroku app name.

### -Action

Action to perform: deploy, logs, status, restart. Defaults to deploy.

### -Branch

Git branch to deploy. Defaults to main.


## Outputs

System.String. Deployment status or command output.


## Examples

### Example 1

`powershell
Deploy-Heroku -AppName "my-app"
        
        Deploys the current git repository to Heroku.
``

### Example 2

`powershell
Deploy-Heroku -AppName "my-app" -Action "logs"
        
        Shows Heroku application logs.
``

## Source

Defined in: ..\profile.d\cloud-enhanced.ps1
