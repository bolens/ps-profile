# Invoke-LlamaCpp

## Synopsis

Executes llama.cpp commands.

## Description

Wrapper function for llama.cpp, a C++ implementation of LLaMA inference. Supports multiple variants (llama-cpp, llama-cpp-cuda, etc.).

## Signature

```powershell
Invoke-LlamaCpp
```

## Parameters

### -Arguments

Arguments to pass to llama-cpp command. Can be used multiple times or as an array.


## Outputs

System.String. Output from llama.cpp execution.


## Examples

### Example 1

`powershell
Invoke-LlamaCpp --help
        Shows llama.cpp help.
``

## Aliases

This function has the following aliases:

- `llama-cpp` - Executes llama.cpp commands.


## Source

Defined in: ..\profile.d\ai-tools.ps1
