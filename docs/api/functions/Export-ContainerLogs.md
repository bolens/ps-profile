# Export-ContainerLogs

## Synopsis

Exports container logs to a file.

## Description

Saves container logs to a file. Works with both Docker and Podman.

## Signature

```powershell
Export-ContainerLogs
```

## Parameters

### -Container

Container name or ID. If not specified, exports logs for all containers.

### -OutputPath

Path to save log file. Defaults to container-logs-{timestamp}.txt.

### -Tail

Number of lines to show from the end of logs. Defaults to all.

### -Since

Show logs since timestamp (e.g., "2023-01-01T00:00:00").


## Outputs

System.String. Path to the exported log file.


## Examples

### Example 1

`powershell
Export-ContainerLogs -Container "my-container"
        
        Exports logs for my-container.
``

### Example 2

`powershell
Export-ContainerLogs -Container "my-container" -OutputPath "logs.txt" -Tail 100
        
        Exports last 100 lines to logs.txt.
``

## Source

Defined in: ..\profile.d\containers-enhanced.ps1
