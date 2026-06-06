# Initialize-PromptFramework

## Synopsis

Initializes a prompt framework with standardized error handling and fallback.

## Description

Provides a standardized way to initialize prompt frameworks with: - Command availability checking - Initialization script execution - Automatic fallback to alternative prompt - Error handling and recovery

## Signature

```powershell
Initialize-PromptFramework
```

## Parameters

### -FrameworkName

Name of the prompt framework (e.g., 'Starship', 'OhMyPosh').

### -CommandName

Name of the CLI command (e.g., 'starship', 'oh-my-posh').

### -InitScript

Script block that performs the initialization. Should handle all framework-specific setup.

### -FallbackPrompt

Optional script block for fallback prompt initialization. Called if command is not available or initialization fails.

### -CheckInitialized

Optional script block to check if framework is already initialized. Should return $true if already initialized, $false otherwise.

### -InstallHint

Installation hint for missing tool warning.


## Outputs

System.Boolean. True if initialization successful, false otherwise.


## Examples

### Example 1

`powershell
Initialize-PromptFramework -FrameworkName 'Starship' -CommandName 'starship' `
            -InitScript { Invoke-StarshipInit } `
            -FallbackPrompt { Initialize-SmartPrompt } `
            -CheckInitialized { Test-StarshipInitialized }
        
        Initializes Starship with fallback to smart prompt.
``

## Source

Defined in: ../profile.d/bootstrap/PromptBase.ps1
