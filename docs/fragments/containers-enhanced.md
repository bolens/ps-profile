# containers-enhanced.ps1

Enhanced container tools and orchestration fragment.

## Overview

The `containers-enhanced.ps1` fragment provides enhanced wrapper functions for container management and orchestration tools, building on the existing `containers.ps1` module:

- **Podman Desktop**: GUI for Podman container management
- **Rancher Desktop**: Container management platform with Kubernetes
- **Kompose**: Convert Docker Compose to Kubernetes manifests
- **Balena**: IoT container deployment platform

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
scoop install podman-desktop rancher-desktop kompose balena-cli

# Or install individually
scoop install podman-desktop  # Podman GUI
scoop install rancher-desktop # Container management GUI
scoop install kompose         # Compose to Kubernetes converter
scoop install balena-cli       # Balena CLI
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
