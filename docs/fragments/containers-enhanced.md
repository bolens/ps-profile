# containers-enhanced.ps1

Enhanced container tools and orchestration fragment.

## Overview

The `containers-enhanced.ps1` fragment provides enhanced wrapper functions for container management and orchestration tools, building on the existing `containers.ps1` module:

- **Podman Desktop**: GUI for Podman container management
- **Rancher Desktop**: Container management platform with Kubernetes
- **Kompose**: Convert Docker Compose to Kubernetes manifests
- **Balena**: IoT container deployment platform
- **Container Management**: Clean containers, export logs, get stats, backup/restore volumes, health checks

## Dependencies

- `bootstrap.ps1` - Core bootstrap functions
- `env.ps1` - Environment configuration
- `containers.ps1` - Base container support (optional)

## Functions

### Start-PodmanDesktop

Launches Podman Desktop GUI.

**Syntax:**

```powershell
Start-PodmanDesktop [<CommonParameters>]
```

**Examples:**

```powershell
# Launch Podman Desktop GUI
Start-PodmanDesktop
```

**Installation:**

```powershell
scoop install podman-desktop
```

---

### Start-RancherDesktop

Launches Rancher Desktop GUI.

**Syntax:**

```powershell
Start-RancherDesktop [<CommonParameters>]
```

**Examples:**

```powershell
# Launch Rancher Desktop GUI
Start-RancherDesktop
```

**Installation:**

```powershell
scoop install rancher-desktop
```

---

### Convert-ComposeToK8s

Converts Docker Compose files to Kubernetes manifests.

**Syntax:**

```powershell
Convert-ComposeToK8s [-ComposeFile <string>] [-OutputPath <string>] [-Format <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

**Parameters:**

- `ComposeFile` - Path to the docker-compose.yml file. Defaults to docker-compose.yml in current directory.
- `OutputPath` - Directory where Kubernetes manifests will be saved. Defaults to current directory.
- `Format` - Output format: yaml, json. Defaults to yaml.

**Examples:**

```powershell
# Convert docker-compose.yml in current directory to Kubernetes manifests
Convert-ComposeToK8s

# Convert specific compose file and save to k8s/ directory
Convert-ComposeToK8s -ComposeFile "docker-compose.prod.yml" -OutputPath "k8s/"

# Convert to JSON format
Convert-ComposeToK8s -Format "json"
```

**Installation:**

```powershell
scoop install kompose
```

---

### Deploy-Balena

Deploys to Balena devices.

**Syntax:**

```powershell
Deploy-Balena [-Action <string>] [-Application <string>] [-Device <string>] [<CommonParameters>]
```

**Parameters:**

- `Action` - Action to perform: push, logs, ssh, status. Defaults to push.
- `Application` - Balena application name.
- `Device` - Optional device UUID or name (required for ssh action).

**Examples:**

```powershell
# Push current directory to Balena application
Deploy-Balena -Application "my-app" -Action "push"

# Show logs from a specific device
Deploy-Balena -Application "my-app" -Action "logs" -Device "device-uuid"

# SSH to a Balena device
Deploy-Balena -Action "ssh" -Device "device-uuid"

# Check application status
Deploy-Balena -Application "my-app" -Action "status"
```

**Installation:**

```powershell
scoop install balena-cli
```

---

### Clean-Containers

Cleans up containers, images, and volumes.

**Syntax:**

```powershell
Clean-Containers [-RemoveVolumes] [-RemoveAll] [-PruneSystem] [-WhatIf] [-Confirm] [<CommonParameters>]
```

**Parameters:**

- `RemoveVolumes` (Switch): Also remove unused volumes.
- `RemoveAll` (Switch): Remove all containers and images, not just unused ones.
- `PruneSystem` (Switch): Prune the entire system (all unused resources).

**Examples:**

```powershell
# Remove stopped containers and unused images
Clean-Containers

# Also remove unused volumes
Clean-Containers -RemoveVolumes

# Remove all containers and images
Clean-Containers -RemoveAll

# Prune entire system
Clean-Containers -PruneSystem
```

**Supported Tools:**

- `docker` or `podman` - Container engine (required)

**Notes:**

- Works with both Docker and Podman
- Uses `Get-ContainerEnginePreference` to detect available engine
- Supports `-WhatIf` and `-Confirm` for safe operations

---

### Export-ContainerLogs

Exports container logs to a file.

**Syntax:**

```powershell
Export-ContainerLogs [-Container <string>] [-OutputPath <string>] [-Tail <int>] [-Since <string>] [<CommonParameters>]
```

**Parameters:**

- `Container` (Optional): Container name or ID. If not specified, exports logs for all containers.
- `OutputPath` (Optional): Path to save log file. Defaults to container-logs-{timestamp}.txt.
- `Tail` (Optional): Number of lines to show from the end of logs. Defaults to all.
- `Since` (Optional): Show logs since timestamp (e.g., "2023-01-01T00:00:00").

**Examples:**

```powershell
# Export logs for specific container
Export-ContainerLogs -Container "my-container"

# Export last 100 lines to specific file
Export-ContainerLogs -Container "my-container" -OutputPath "logs.txt" -Tail 100

# Export logs since a specific time
Export-ContainerLogs -Container "my-container" -Since "2023-01-01T00:00:00"

# Export logs for all containers
Export-ContainerLogs
```

**Supported Tools:**

- `docker` or `podman` - Container engine (required)

**Notes:**

- Creates timestamped log files if OutputPath not specified
- Combines logs from multiple containers into single file
- Returns path to exported log file

---

### Get-ContainerStats

Gets container resource usage statistics.

**Syntax:**

```powershell
Get-ContainerStats [-Container <string>] [-NoStream] [-Format <string>] [<CommonParameters>]
```

**Parameters:**

- `Container` (Optional): Container name or ID. If not specified, shows stats for all containers.
- `NoStream` (Switch): Disable streaming (show stats once and exit).
- `Format` (Optional): Output format: table, json. Defaults to table.

**Examples:**

```powershell
# Show real-time stats for all containers
Get-ContainerStats

# Show one-time stats for specific container
Get-ContainerStats -Container "my-container" -NoStream

# Get stats in JSON format
Get-ContainerStats -Container "my-container" -Format json -NoStream
```

**Supported Tools:**

- `docker` or `podman` - Container engine (required)

**Notes:**

- Real-time streaming by default (use `-NoStream` for one-time stats)
- Shows CPU, memory, network, and I/O statistics
- Works with both Docker and Podman

---

### Backup-ContainerVolumes

Backs up container volumes to a tar archive.

**Syntax:**

```powershell
Backup-ContainerVolumes [-Volume <string>] [-OutputPath <string>] [-Compress] [-WhatIf] [-Confirm] [<CommonParameters>]
```

**Parameters:**

- `Volume` (Optional): Volume name. If not specified, backs up all volumes.
- `OutputPath` (Optional): Path to save backup file. Defaults to volume-backup-{timestamp}.tar.gz.
- `Compress` (Switch): Compress the backup archive (gzip).

**Examples:**

```powershell
# Backup specific volume
Backup-ContainerVolumes -Volume "my-volume"

# Backup all volumes with compression
Backup-ContainerVolumes -Compress

# Backup to specific path
Backup-ContainerVolumes -Volume "my-volume" -OutputPath "backup.tar.gz"
```

**Supported Tools:**

- `docker` or `podman` - Container engine (required)

**Notes:**

- Creates timestamped backup files if OutputPath not specified
- Uses temporary containers to access volume data
- Returns path to backup file

---

### Restore-ContainerVolumes

Restores container volumes from a backup archive.

**Syntax:**

```powershell
Restore-ContainerVolumes [-BackupPath] <string> [-Volume <string>] [-CreateVolume] [-WhatIf] [-Confirm] [<CommonParameters>]
```

**Parameters:**

- `BackupPath` (Mandatory): Path to the backup archive file.
- `Volume` (Optional): Volume name to restore to. If not specified, creates a new volume.
- `CreateVolume` (Switch): Create a new volume if it doesn't exist.

**Examples:**

```powershell
# Restore from backup to new volume
Restore-ContainerVolumes -BackupPath "volume-backup.tar.gz"

# Restore to specific volume
Restore-ContainerVolumes -BackupPath "backup.tar.gz" -Volume "my-volume" -CreateVolume
```

**Supported Tools:**

- `docker` or `podman` - Container engine (required)

**Notes:**

- Creates new volume with timestamp if Volume not specified
- Uses temporary containers to restore volume data
- Returns name of restored volume

---

### Health-CheckContainers

Performs health checks on all running containers.

**Syntax:**

```powershell
Health-CheckContainers [-Container <string>] [-Format <string>] [<CommonParameters>]
```

**Parameters:**

- `Container` (Optional): Container name or ID. If not specified, checks all containers.
- `Format` (Optional): Output format: table, json. Defaults to table.

**Examples:**

```powershell
# Check health of all running containers
Health-CheckContainers

# Check health of specific container
Health-CheckContainers -Container "my-container"

# Get health status in JSON format
Health-CheckContainers -Format json
```

**Supported Tools:**

- `docker` or `podman` - Container engine (required)

**Notes:**

- Returns health status for each container
- Shows failing streak count and health check logs
- Returns "no-healthcheck" for containers without health checks configured
- Works with both Docker and Podman

---

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions check for tool availability using `Test-CachedCommand`
- Missing tools display installation hints using `Write-MissingToolWarning`
- Functions return `$null` when tools are unavailable
- No errors are thrown for missing tools (graceful degradation)

## Installation

Install required tools using Scoop:

```powershell
# Install all enhanced container tools
scoop install podman-desktop rancher-desktop kompose balena-cli docker podman

# Or install individually
scoop install podman-desktop  # Podman GUI
scoop install rancher-desktop # Container management GUI
scoop install kompose         # Compose to Kubernetes converter
scoop install balena-cli      # Balena CLI
scoop install docker          # Docker engine (for container management functions)
scoop install podman          # Podman engine (alternative to Docker)
```

## Testing

The fragment includes comprehensive test coverage:

- **Unit tests**: Individual function tests with mocking
- **Integration tests**: Fragment loading and function registration
- **Performance tests**: Load time and function execution performance

Run tests:

```powershell
# Run unit tests
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/containers-enhanced.ps1

# Run integration tests
Invoke-Pester tests/integration/tools/containers-enhanced.tests.ps1

# Run performance tests
Invoke-Pester tests/performance/containers-enhanced-performance.tests.ps1
```

## Notes

- All functions are idempotent and can be safely called multiple times
- Functions use `Set-AgentModeFunction` for registration
- This module enhances existing containers.ps1 module
- Podman Desktop and Rancher Desktop are GUI applications
- Kompose requires Docker Compose files to convert
- Balena deployments require authentication and application setup
- Convert-ComposeToK8s creates Kubernetes deployment and service manifests
