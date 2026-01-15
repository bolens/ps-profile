# Invoke-ComfyUI

## Synopsis

Executes ComfyUI CLI commands.

## Description

Wrapper function for ComfyUI CLI (comfy) that executes commands for managing ComfyUI installations, custom nodes, and models. ComfyUI is a powerful node-based Stable Diffusion UI.

## Signature

```powershell
Invoke-ComfyUI
```

## Parameters

### -Arguments

Arguments to pass to comfy command. Can be used multiple times or as an array.


## Outputs

System.String. Output from ComfyUI CLI execution.


## Examples

### Example 1

`powershell
Invoke-ComfyUI install
        Installs ComfyUI.
``

### Example 2

`powershell
Invoke-ComfyUI launch
        Launches ComfyUI server.
``

### Example 3

`powershell
Invoke-ComfyUI node install custom-node-name
        Installs a custom node.
``

## Aliases

This function has the following aliases:

- `comfy` - Executes ComfyUI CLI commands.


## Source

Defined in: ..\profile.d\ai-tools.ps1
