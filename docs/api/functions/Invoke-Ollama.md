# Invoke-Ollama

## Synopsis

Executes Ollama commands.

## Description

Wrapper function for Ollama CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-Ollama
```

## Parameters

### -Arguments

Arguments to pass to ollama.


## Examples

### Example 1

`powershell
Invoke-Ollama list
``

### Example 2

`powershell
Invoke-Ollama --version
``

## Aliases

This function has the following aliases:

- `ol` - Executes Ollama commands.


## Source

Defined in: ..\profile.d\ollama.ps1
