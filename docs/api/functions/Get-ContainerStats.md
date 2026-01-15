# Get-ContainerStats

## Synopsis

Gets container resource usage statistics.

## Description

Displays real-time or one-time statistics for containers. Works with both Docker and Podman.

## Signature

```powershell
Get-ContainerStats
```

## Parameters

### -Container

Container name or ID. If not specified, shows stats for all containers.

### -NoStream

Disable streaming (show stats once and exit).

### -Format

Output format: table, json. Defaults to table.


## Outputs

System.String. Container statistics output.


## Examples

### Example 1

`powershell
Get-ContainerStats
        
        Shows real-time stats for all containers.
``

### Example 2

`powershell
Get-ContainerStats -Container "my-container" -NoStream
        
        Shows one-time stats for my-container.
``

## Source

Defined in: ..\profile.d\containers-enhanced.ps1
