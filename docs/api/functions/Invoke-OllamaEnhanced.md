# Invoke-OllamaEnhanced

## Synopsis

Executes Ollama commands with enhanced functionality.

## Description

Enhanced wrapper for Ollama CLI that provides additional functionality beyond the basic ollama.ps1 wrapper. Supports all Ollama commands.

## Signature

```powershell
Invoke-OllamaEnhanced
```

## Parameters

### -Arguments

Arguments to pass to ollama command. Can be used multiple times or as an array.


## Outputs

System.String. Output from Ollama execution.


## Examples

### Example 1

`powershell
Invoke-OllamaEnhanced list
        Lists available Ollama models.
``

### Example 2

`powershell
Invoke-OllamaEnhanced run llama2 "Hello, world!"
        Runs a prompt with the llama2 model.
``

## Aliases

This function has the following aliases:

- `ollama-enhanced` - Executes Ollama commands with enhanced functionality.


## Source

Defined in: ..\profile.d\ai-tools.ps1
