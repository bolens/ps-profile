# Invoke-LMStudio

## Synopsis

Executes LM Studio CLI commands.

## Description

Wrapper function for LM Studio CLI (lms) that executes commands for managing local LLMs. LM Studio provides a user-friendly interface for running large language models locally.

## Signature

```powershell
Invoke-LMStudio
```

## Parameters

### -Arguments

Arguments to pass to lms command. Can be used multiple times or as an array.


## Outputs

System.String. Output from LM Studio CLI execution.


## Examples

### Example 1

`powershell
Invoke-LMStudio list
        Lists available models in LM Studio.
``

### Example 2

`powershell
Invoke-LMStudio serve
        Starts the LM Studio server.
``

## Aliases

This function has the following aliases:

- `lms` - Executes LM Studio CLI commands.


## Source

Defined in: ..\profile.d\ai-tools.ps1
