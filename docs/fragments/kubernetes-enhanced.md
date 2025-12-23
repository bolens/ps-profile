# kubernetes-enhanced.ps1

Enhanced Kubernetes tools and orchestration fragment.

## Overview

The `kubernetes-enhanced.ps1` fragment provides enhanced wrapper functions for Kubernetes management and orchestration tools, building on the existing `kubectl.ps1` and `kube.ps1` modules:

- **Context Management**: Switch Kubernetes contexts with kubectx or kubectl
- **Namespace Management**: Switch namespaces with kubens or kubectl
- **Log Tailing**: Multi-pod log aggregation with stern or kubectl
- **Resource Management**: Enhanced resource queries with kubectl
- **Local Clusters**: Minikube cluster management
- **TUI Tools**: k9s terminal UI for Kubernetes

## Dependencies

- `bootstrap.ps1` - Core bootstrap functions
- `env.ps1` - Environment configuration
- `kubectl.ps1` - Base kubectl support (optional)
- `helm.ps1` - Helm support (optional)

## Functions

### Set-KubeContext

Switches the active Kubernetes context.

**Syntax:**

```powershell
Set-KubeContext [-ContextName <string>] [-List] [<CommonParameters>]
```

**Parameters:**

- `ContextName` - Name of the context to switch to. If not specified, lists available contexts.
- `List` - List all available contexts instead of switching.

**Examples:**

```powershell
# List all available contexts
Set-KubeContext -List

# Switch to a specific context
Set-KubeContext -ContextName "my-context"

# List contexts (alternative syntax)
Set-KubeContext
```

**Installation:**

```powershell
# kubectx (optional, preferred)
scoop install kubectx

# kubectl (required fallback)
scoop install kubectl
```

---

### Set-KubeNamespace

Switches the active Kubernetes namespace.

**Syntax:**

```powershell
Set-KubeNamespace [-Namespace <string>] [-List] [<CommonParameters>]
```

**Parameters:**

- `Namespace` - Name of the namespace to switch to. If not specified, lists available namespaces.
- `List` - List all available namespaces instead of switching.

**Examples:**

```powershell
# List all available namespaces
Set-KubeNamespace -List

# Switch to a specific namespace
Set-KubeNamespace -Namespace "production"

# List namespaces (alternative syntax)
Set-KubeNamespace
```

**Installation:**

```powershell
# kubens (optional, preferred)
scoop install kubens

# kubectl (required fallback)
scoop install kubectl
```

---

### Tail-KubeLogs

Tails logs from Kubernetes pods.

**Syntax:**

```powershell
Tail-KubeLogs -Pattern <string> [-Namespace <string>] [-Container <string>] [-Follow] [<CommonParameters>]
```

**Parameters:**

- `Pattern` (Required) - Pod name pattern to match (supports regex with stern).
- `Namespace` - Kubernetes namespace. Defaults to current namespace.
- `Container` - Optional container name to filter logs.
- `Follow` - Follow log output (like tail -f). Defaults to true.

**Examples:**

```powershell
# Tail logs from all pods matching pattern
Tail-KubeLogs -Pattern "my-app"

# Tail logs with namespace and container filter
Tail-KubeLogs -Pattern "nginx" -Namespace "production" -Container "web"
```

**Installation:**

```powershell
# stern (optional, preferred for multi-pod log aggregation)
scoop install stern

# kubectl (required fallback)
scoop install kubectl
```

---

### Get-KubeResources

Gets Kubernetes resource information.

**Syntax:**

```powershell
Get-KubeResources -ResourceType <string> [-ResourceName <string>] [-Namespace <string>] [-OutputFormat <string>] [<CommonParameters>]
```

**Parameters:**

- `ResourceType` (Required) - Kubernetes resource type (e.g., pods, services, deployments).
- `ResourceName` - Optional specific resource name.
- `Namespace` - Kubernetes namespace. Defaults to current namespace.
- `OutputFormat` - Output format: wide, yaml, json. Defaults to wide.

**Examples:**

```powershell
# List all pods in current namespace
Get-KubeResources -ResourceType "pods"

# Get deployments in production namespace as YAML
Get-KubeResources -ResourceType "deployments" -Namespace "production" -OutputFormat "yaml"

# Get specific pod details
Get-KubeResources -ResourceType "pods" -ResourceName "my-pod"
```

**Installation:**

```powershell
scoop install kubectl
```

---

### Start-Minikube

Starts a Minikube Kubernetes cluster.

**Syntax:**

```powershell
Start-Minikube [-Profile <string>] [-Driver <string>] [-Status] [<CommonParameters>]
```

**Parameters:**

- `Profile` - Minikube profile name. Defaults to minikube.
- `Driver` - Minikube driver: docker, hyperv, virtualbox, etc.
- `Status` - Check Minikube status instead of starting.

**Examples:**

```powershell
# Start Minikube cluster with default settings
Start-Minikube

# Start with custom profile and driver
Start-Minikube -Profile "dev" -Driver "docker"

# Check Minikube status
Start-Minikube -Status
```

**Installation:**

```powershell
scoop install minikube
```

---

### Start-K9s

Launches k9s Kubernetes TUI.

**Syntax:**

```powershell
Start-K9s [-Namespace <string>] [<CommonParameters>]
```

**Parameters:**

- `Namespace` - Optional namespace to open k9s in.

**Examples:**

```powershell
# Launch k9s with default settings
Start-K9s

# Launch k9s in specific namespace
Start-K9s -Namespace "production"
```

**Installation:**

```powershell
scoop install k9s
```

---

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions check for tool availability using `Test-CachedCommand`
- Missing tools display installation hints using `Write-MissingToolWarning`
- Functions return `$null` when tools are unavailable
- No errors are thrown for missing tools (graceful degradation)
- Functions prefer specialized tools (kubectx, kubens, stern) but fallback to kubectl

## Installation

Install required tools using Scoop:

```powershell
# Install all enhanced Kubernetes tools
scoop install kubectl kubectx kubens stern k9s minikube

# Or install individually
scoop install kubectl   # Kubernetes CLI (required)
scoop install kubectx   # Context switcher (optional, preferred)
scoop install kubens    # Namespace switcher (optional, preferred)
scoop install stern     # Log tailing (optional, preferred)
scoop install k9s       # Kubernetes TUI
scoop install minikube  # Local Kubernetes cluster
```

## Testing

The fragment includes comprehensive test coverage:

- **Unit tests**: Individual function tests with mocking
- **Integration tests**: Fragment loading and function registration
- **Performance tests**: Load time and function execution performance

Run tests:

```powershell
# Run unit tests
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/kubernetes-enhanced.ps1

# Run integration tests
Invoke-Pester tests/integration/tools/kubernetes-enhanced.tests.ps1

# Run performance tests
Invoke-Pester tests/performance/kubernetes-enhanced-performance.tests.ps1
```

## Notes

- All functions are idempotent and can be safely called multiple times
- Functions use `Set-AgentModeFunction` for registration
- This module enhances existing kubectl.ps1 and kube.ps1 modules
- Set-KubeContext and Set-KubeNamespace prefer kubectx/kubens but fallback to kubectl
- Tail-KubeLogs prefers stern for better multi-pod log aggregation
- Start-K9s provides an interactive TUI for Kubernetes management
- Minikube requires a virtualization driver (Docker, Hyper-V, VirtualBox, etc.)
- Functions require kubectl to be installed for fallback functionality
