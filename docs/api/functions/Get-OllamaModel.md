# Get-OllamaModel

## Synopsis

Downloads an Ollama model.

## Description

Wrapper for ollama pull command.

## Signature

```powershell
Get-OllamaModel
```

## Parameters

### -Model

Name of the model to download.


## Examples

### Example 1

`powershell
Get-OllamaModel -Model "llama2"
``

### Example 2

`powershell
Get-OllamaModel -Model "mistral"
``

## Aliases

This function has the following aliases:

- `ol-pull` - Downloads an Ollama model.


## Source

Defined in: ..\profile.d\ollama.ps1
