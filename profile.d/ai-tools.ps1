# ===============================================
# ai-tools.ps1
# AI and LLM tools
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    AI tools fragment for AI and LLM command-line tools.

.DESCRIPTION
    Provides wrapper functions for AI and LLM tools:
    - ollama: Local LLM runner (enhanced wrapper)
    - lms: LM Studio CLI for managing local LLMs
    - koboldcpp: KoboldCpp LLM server
    - llamafile: Single-file LLM runner
    - llama-cpp: llama.cpp inference engine
    - comfy: ComfyUI CLI for managing ComfyUI installations and workflows

.NOTES
    All functions gracefully degrade when tools are not installed.
    Use Register-ToolWrapper for simple wrappers and custom functions for complex operations.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'ai-tools') { return }
    }
    
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = $null
        if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            try {
                $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
            }
            catch {
                # Get-RepoRoot expects scripts/ subdirectory, but we're in profile.d/
                # Fall back to manual path resolution
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
        }
        else {
            $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        
        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # Ollama - Local LLM runner (enhanced)
    # ===============================================

    <#
    .SYNOPSIS
        Executes Ollama commands with enhanced functionality.
    
    .DESCRIPTION
        Enhanced wrapper for Ollama CLI that provides additional functionality
        beyond the basic ollama.ps1 wrapper. Supports all Ollama commands.
    
    .PARAMETER Arguments
        Arguments to pass to ollama command.
        Can be used multiple times or as an array.
    
    .EXAMPLE
        Invoke-OllamaEnhanced list
        Lists available Ollama models.
    
    .EXAMPLE
        Invoke-OllamaEnhanced run llama2 "Hello, world!"
        Runs a prompt with the llama2 model.
    
    .OUTPUTS
        System.String. Output from Ollama execution.
    #>
    function Invoke-OllamaEnhanced {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'ollama')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'ollama' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install ollama"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'ollama' -InstallHint $installHint
            }
            else {
                Write-Warning "ollama not found. $installHint"
            }
            return $null
        }

        try {
            $result = & ollama $Arguments 2>&1
            return $result
        }
        catch {
            Write-Error "Failed to run ollama: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Invoke-OllamaEnhanced -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-OllamaEnhanced' -Body ${function:Invoke-OllamaEnhanced}
    }
    if (-not (Get-Alias ollama-enhanced -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'ollama-enhanced' -Target 'Invoke-OllamaEnhanced'
        }
        else {
            Set-Alias -Name 'ollama-enhanced' -Value 'Invoke-OllamaEnhanced' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # LM Studio CLI - LM Studio CLI
    # ===============================================

    <#
    .SYNOPSIS
        Executes LM Studio CLI commands.
    
    .DESCRIPTION
        Wrapper function for LM Studio CLI (lms) that executes commands for managing
        local LLMs. LM Studio provides a user-friendly interface for running
        large language models locally.
    
    .PARAMETER Arguments
        Arguments to pass to lms command.
        Can be used multiple times or as an array.
    
    .EXAMPLE
        Invoke-LMStudio list
        Lists available models in LM Studio.
    
    .EXAMPLE
        Invoke-LMStudio serve
        Starts the LM Studio server.
    
    .OUTPUTS
        System.String. Output from LM Studio CLI execution.
    #>
    function Invoke-LMStudio {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        # Check for lms command (LM Studio CLI)
        $lmsCmd = $null
        if (Test-CachedCommand 'lms') {
            $lmsCmd = 'lms'
        }
        # Also check for lms.exe in common locations
        elseif (Test-Path -LiteralPath "$env:USERPROFILE\.lmstudio\bin\lms.exe") {
            $lmsCmd = "$env:USERPROFILE\.lmstudio\bin\lms.exe"
        }
        elseif (Test-Path -LiteralPath "$env:USERPROFILE\.cache\lm-studio\bin\lms.exe") {
            $lmsCmd = "$env:USERPROFILE\.cache\lm-studio\bin\lms.exe"
        }

        if (-not $lmsCmd) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'lmstudio' -RepoRoot $repoRoot
            }
            else {
                "Install LM Studio from https://lmstudio.ai/ and run 'lms bootstrap' to enable CLI"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'lms' -InstallHint $installHint
            }
            else {
                Write-Warning "lms (LM Studio CLI) not found. $installHint"
            }
            return $null
        }

        try {
            $result = & $lmsCmd $Arguments 2>&1
            return $result
        }
        catch {
            $cmdName = $lmsCmd
            Write-Error "Failed to run ${cmdName}: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Invoke-LMStudio -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-LMStudio' -Body ${function:Invoke-LMStudio}
    }
    if (-not (Get-Alias lms -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'lms' -Target 'Invoke-LMStudio'
        }
        else {
            Set-Alias -Name 'lms' -Value 'Invoke-LMStudio' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # KoboldCpp - KoboldCpp LLM server
    # ===============================================

    <#
    .SYNOPSIS
        Executes KoboldCpp commands.
    
    .DESCRIPTION
        Wrapper function for KoboldCpp, a lightweight LLM inference server
        that provides a web interface and API for running large language models.
    
    .PARAMETER Arguments
        Arguments to pass to koboldcpp command.
        Can be used multiple times or as an array.
    
    .EXAMPLE
        Invoke-KoboldCpp --help
        Shows KoboldCpp help.
    
    .EXAMPLE
        Start-KoboldCppServer -Model "llama-2-7b.gguf"
        Starts KoboldCpp server with a specific model.
    
    .OUTPUTS
        System.String. Output from KoboldCpp execution.
    #>
    function Invoke-KoboldCpp {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'koboldcpp')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'koboldcpp' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install koboldcpp"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'koboldcpp' -InstallHint $installHint
            }
            else {
                Write-Warning "koboldcpp not found. $installHint"
            }
            return $null
        }

        try {
            $result = & koboldcpp $Arguments 2>&1
            return $result
        }
        catch {
            Write-Error "Failed to run koboldcpp: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Invoke-KoboldCpp -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-KoboldCpp' -Body ${function:Invoke-KoboldCpp}
    }
    if (-not (Get-Alias koboldcpp -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'koboldcpp' -Target 'Invoke-KoboldCpp'
        }
        else {
            Set-Alias -Name 'koboldcpp' -Value 'Invoke-KoboldCpp' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # Llamafile - Single-file LLM runner
    # ===============================================

    <#
    .SYNOPSIS
        Executes Llamafile commands.
    
    .DESCRIPTION
        Wrapper function for Llamafile, a single-file LLM runner that combines
        a model and inference engine into one executable file.
    
    .PARAMETER Arguments
        Arguments to pass to llamafile command.
        Can be used multiple times or as an array.
    
    .PARAMETER Model
        Path to the llamafile model file.
    
    .PARAMETER Prompt
        Prompt to send to the model.
    
    .EXAMPLE
        Invoke-Llamafile --help
        Shows Llamafile help.
    
    .EXAMPLE
        Invoke-Llamafile -Model "mistral-7b-instruct-v0.2.Q4_K_M.llamafile" -Prompt "Hello, world!"
        Runs a prompt with a specific llamafile model.
    
    .OUTPUTS
        System.String. Output from Llamafile execution.
    #>
    function Invoke-Llamafile {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments,
            
            [Parameter()]
            [string]$Model,
            
            [Parameter()]
            [string]$Prompt
        )

        if (-not (Test-CachedCommand 'llamafile')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'llamafile' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install llamafile"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'llamafile' -InstallHint $installHint
            }
            else {
                Write-Warning "llamafile not found. $installHint"
            }
            return $null
        }

        try {
            $cmdArgs = @()
            if (-not [string]::IsNullOrWhiteSpace($Model)) {
                $cmdArgs += $Model
            }
            if (-not [string]::IsNullOrWhiteSpace($Prompt)) {
                $cmdArgs += '--prompt', $Prompt
            }
            if ($Arguments) {
                $cmdArgs += $Arguments
            }
            $result = & llamafile $cmdArgs 2>&1
            return $result
        }
        catch {
            Write-Error "Failed to run llamafile: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Invoke-Llamafile -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-Llamafile' -Body ${function:Invoke-Llamafile}
    }
    if (-not (Get-Alias llamafile -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'llamafile' -Target 'Invoke-Llamafile'
        }
        else {
            Set-Alias -Name 'llamafile' -Value 'Invoke-Llamafile' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # llama.cpp - llama.cpp inference engine
    # ===============================================

    <#
    .SYNOPSIS
        Executes llama.cpp commands.
    
    .DESCRIPTION
        Wrapper function for llama.cpp, a C++ implementation of LLaMA inference.
        Supports multiple variants (llama-cpp, llama-cpp-cuda, etc.).
    
    .PARAMETER Arguments
        Arguments to pass to llama-cpp command.
        Can be used multiple times or as an array.
    
    .EXAMPLE
        Invoke-LlamaCpp --help
        Shows llama.cpp help.
    
    .OUTPUTS
        System.String. Output from llama.cpp execution.
    #>
    function Invoke-LlamaCpp {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        # Check for various llama-cpp variants
        $llamaCmd = $null
        if (Test-CachedCommand 'llama-cpp-cuda') {
            $llamaCmd = 'llama-cpp-cuda'
        }
        elseif (Test-CachedCommand 'llama-cpp') {
            $llamaCmd = 'llama-cpp'
        }
        elseif (Test-CachedCommand 'llama.cpp') {
            $llamaCmd = 'llama.cpp'
        }

        if (-not $llamaCmd) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'llama-cpp' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install llama-cpp-cuda (or llama-cpp)"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'llama-cpp' -InstallHint $installHint
            }
            else {
                Write-Warning "llama-cpp not found. $installHint"
            }
            return $null
        }

        try {
            $result = & $llamaCmd $Arguments 2>&1
            return $result
        }
        catch {
            $cmdName = $llamaCmd
            Write-Error "Failed to run ${cmdName}: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Invoke-LlamaCpp -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-LlamaCpp' -Body ${function:Invoke-LlamaCpp}
    }
    if (-not (Get-Alias llama-cpp -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'llama-cpp' -Target 'Invoke-LlamaCpp'
        }
        else {
            Set-Alias -Name 'llama-cpp' -Value 'Invoke-LlamaCpp' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # ComfyUI CLI - ComfyUI CLI
    # ===============================================

    <#
    .SYNOPSIS
        Executes ComfyUI CLI commands.
    
    .DESCRIPTION
        Wrapper function for ComfyUI CLI (comfy) that executes commands for managing
        ComfyUI installations, custom nodes, and models. ComfyUI is a powerful
        node-based Stable Diffusion UI.
    
    .PARAMETER Arguments
        Arguments to pass to comfy command.
        Can be used multiple times or as an array.
    
    .EXAMPLE
        Invoke-ComfyUI install
        Installs ComfyUI.
    
    .EXAMPLE
        Invoke-ComfyUI launch
        Launches ComfyUI server.
    
    .EXAMPLE
        Invoke-ComfyUI node install custom-node-name
        Installs a custom node.
    
    .OUTPUTS
        System.String. Output from ComfyUI CLI execution.
    #>
    function Invoke-ComfyUI {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        # Check for comfy command (ComfyUI CLI)
        # Note: comfy-cli is installed via pip/pipx, not Scoop
        if (-not (Test-CachedCommand 'comfy')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'comfy-cli' -RepoRoot $repoRoot
            }
            else {
                "Install with: pip install comfy-cli (or pipx install comfy-cli)"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'comfy' -InstallHint $installHint
            }
            else {
                Write-Warning "comfy (ComfyUI CLI) not found. $installHint"
            }
            return $null
        }

        try {
            $result = & comfy $Arguments 2>&1
            return $result
        }
        catch {
            Write-Error "Failed to run comfy: $($_.Exception.Message)"
            return $null
        }
    }

    if (-not (Test-Path Function:\Invoke-ComfyUI -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Invoke-ComfyUI' -Body ${function:Invoke-ComfyUI}
    }
    if (-not (Get-Alias comfy -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'comfy' -Target 'Invoke-ComfyUI'
        }
        else {
            Set-Alias -Name 'comfy' -Value 'Invoke-ComfyUI' -ErrorAction SilentlyContinue
        }
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'ai-tools'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'ai-tools' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load ai-tools fragment: $($_.Exception.Message)"
    }
}
