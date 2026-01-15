# Invoke-Llamafile

## Synopsis

Executes Llamafile commands.

## Description

Wrapper function for Llamafile, a single-file LLM runner that combines a model and inference engine into one executable file.

## Signature

```powershell
Invoke-Llamafile
```

## Parameters

### -Arguments

Arguments to pass to llamafile command. Can be used multiple times or as an array.

### -Model

Path to the llamafile model file.

### -Prompt

Prompt to send to the model.


## Outputs

System.String. Output from Llamafile execution.


## Examples

### Example 1

`powershell
Invoke-Llamafile --help
        Shows Llamafile help.
``

### Example 2

`powershell
Invoke-Llamafile -Model "mistral-7b-instruct-v0.2.Q4_K_M.llamafile" -Prompt "Hello, world!"
        Runs a prompt with a specific llamafile model.
``

## Aliases

This function has the following aliases:

- `llamafile` - Executes Llamafile commands.


## Source

Defined in: ..\profile.d\ai-tools.ps1
