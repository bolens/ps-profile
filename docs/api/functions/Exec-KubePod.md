# Exec-KubePod

## Synopsis

Executes commands in Kubernetes pods.

## Description

Runs commands inside Kubernetes pods using kubectl exec. Supports interactive and non-interactive execution.

## Signature

```powershell
Exec-KubePod
```

## Parameters

### -Pod

Pod name or pattern to match.

### -Command

Command to execute. Defaults to shell (/bin/sh or /bin/bash).

### -Container

Optional container name if pod has multiple containers.

### -Namespace

Kubernetes namespace. Defaults to current namespace.

### -Interactive

Run command interactively (default: false).

### -Tty

Allocate a TTY for the command (default: false).


## Outputs

System.String. Command output.


## Examples

### Example 1

`powershell
Exec-KubePod -Pod "my-app" -Command "ls -la"
        
        Executes ls -la in my-app pod.
``

### Example 2

`powershell
Exec-KubePod -Pod "nginx" -Container "web" -Command "/bin/sh" -Interactive -Tty
        
        Opens interactive shell in nginx pod, web container.
``

## Source

Defined in: ..\profile.d\kubernetes-enhanced.ps1
