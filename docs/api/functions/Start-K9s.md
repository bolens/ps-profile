# Start-K9s

## Synopsis

Launches k9s Kubernetes TUI.

## Description

Starts k9s, a terminal UI for managing Kubernetes clusters. Provides an interactive interface for viewing and managing resources.

## Signature

```powershell
Start-K9s
```

## Parameters

### -Namespace

Optional namespace to open k9s in.


## Examples

### Example 1

`powershell
Start-K9s
        
        Launches k9s with default settings.
``

### Example 2

`powershell
Start-K9s -Namespace "production"
        
        Launches k9s in the production namespace.
``

## Source

Defined in: ..\profile.d\kubernetes-enhanced.ps1
