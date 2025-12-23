# ===============================================
# ollama.ps1
# Ollama AI model helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Ollama AI model helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Ollama operations.
    Functions check for ollama availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Ollama
    Author: PowerShell Profile
#>

# Ollama execute - run ollama with arguments
<#
.SYNOPSIS
    Executes Ollama commands.

.DESCRIPTION
    Wrapper function for Ollama CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to ollama.

.EXAMPLE
    Invoke-Ollama list

.EXAMPLE
    Invoke-Ollama --version
#>
function Invoke-Ollama {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand ollama) {
        ollama @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'ollama' -InstallHint 'Install with: scoop install ollama'
    }
}

# Ollama list - list available models
<#
.SYNOPSIS
    Lists available Ollama models.

.DESCRIPTION
    Wrapper for ollama list command.

.EXAMPLE
    Get-OllamaModelList
#>
function Get-OllamaModelList {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand ollama) {
        ollama list
    }
    else {
        Write-MissingToolWarning -Tool 'ollama' -InstallHint 'Install with: scoop install ollama'
    }
}

# Ollama run - run an AI model interactively
<#
.SYNOPSIS
    Runs an Ollama model interactively.

.DESCRIPTION
    Wrapper for ollama run command.

.PARAMETER Model
    Name of the model to run.

.EXAMPLE
    Start-OllamaModel -Model "llama2"

.EXAMPLE
    Start-OllamaModel -Model "mistral"
#>
function Start-OllamaModel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Model
    )
    
    if (Test-CachedCommand ollama) {
        ollama run $Model
    }
    else {
        Write-MissingToolWarning -Tool 'ollama' -InstallHint 'Install with: scoop install ollama'
    }
}

# Ollama pull - download an AI model
<#
.SYNOPSIS
    Downloads an Ollama model.

.DESCRIPTION
    Wrapper for ollama pull command.

.PARAMETER Model
    Name of the model to download.

.EXAMPLE
    Get-OllamaModel -Model "llama2"

.EXAMPLE
    Get-OllamaModel -Model "mistral"
#>
function Get-OllamaModel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Model
    )
    
    if (Test-CachedCommand ollama) {
        ollama pull $Model
    }
    else {
        Write-MissingToolWarning -Tool 'ollama' -InstallHint 'Install with: scoop install ollama'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ol' -Target 'Invoke-Ollama'
    Set-AgentModeAlias -Name 'ol-list' -Target 'Get-OllamaModelList'
    Set-AgentModeAlias -Name 'ol-run' -Target 'Start-OllamaModel'
    Set-AgentModeAlias -Name 'ol-pull' -Target 'Get-OllamaModel'
}
else {
    Set-Alias -Name 'ol' -Value 'Invoke-Ollama' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ol-list' -Value 'Get-OllamaModelList' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ol-run' -Value 'Start-OllamaModel' -ErrorAction SilentlyContinue
    Set-Alias -Name 'ol-pull' -Value 'Get-OllamaModel' -ErrorAction SilentlyContinue
}
