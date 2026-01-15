# Set-GcpProject

## Synopsis

Switches the active GCP project.

## Description

Changes the active Google Cloud Platform project for the current session. Uses gcloud to list and set projects.

## Signature

```powershell
Set-GcpProject
```

## Parameters

### -ProjectId

Project ID to switch to.

### -List

List all available projects instead of switching.


## Outputs

System.String. Project information or list of projects.


## Examples

### Example 1

`powershell
Set-GcpProject -ProjectId "my-project-id"
        
        Switches to the specified project.
``

### Example 2

`powershell
Set-GcpProject -List
        
        Lists all available projects.
``

## Source

Defined in: ..\profile.d\cloud-enhanced.ps1
