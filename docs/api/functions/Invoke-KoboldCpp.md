# Invoke-KoboldCpp

## Synopsis

Executes KoboldCpp commands.

## Description

Wrapper function for KoboldCpp, a lightweight LLM inference server that provides a web interface and API for running large language models.

## Signature

```powershell
Invoke-KoboldCpp
```

## Parameters

### -Arguments

Arguments to pass to koboldcpp command. Can be used multiple times or as an array.


## Outputs

System.String. Output from KoboldCpp execution.


## Examples

### Example 1

`powershell
Invoke-KoboldCpp --help
        Shows KoboldCpp help.
``

### Example 2

`powershell
Start-KoboldCppServer -Model "llama-2-7b.gguf"
        Starts KoboldCpp server with a specific model.
``

## Aliases

This function has the following aliases:

- `koboldcpp` - Executes KoboldCpp commands.


## Source

Defined in: ..\profile.d\ai-tools.ps1
