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
    

    .OUTPUTS
        System.String. Output from Ollama execution.

    .EXAMPLE
        Invoke-OllamaEnhanced list
        Lists available Ollama models.
    

    .EXAMPLE
        Invoke-OllamaEnhanced run llama2 "Hello, world!"
        Runs a prompt with the llama2 model.
    #>
    function Invoke-OllamaEnhanced {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'ollama')) {
            Invoke-MissingToolWarning -ToolName 'ollama'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'ai.ollama.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & ollama $Arguments 2>&1
            }
        }
        else {
            try {
                $result = & ollama $Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run ollama: $($_.Exception.Message)"
                return $null
            }
        }
    }

    Set-AgentModeFunction -Name 'Invoke-OllamaEnhanced' -Body ${function:Invoke-OllamaEnhanced}
    if (-not (Get-Alias ollama-enhanced -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'ollama-enhanced' -Target 'Invoke-OllamaEnhanced'
        }
        else {
            Set-AgentModeAlias -Name 'ollama-enhanced' -Target 'Invoke-OllamaEnhanced'
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
    

    .OUTPUTS
        System.String. Output from LM Studio CLI execution.

    .EXAMPLE
        Invoke-LMStudio list
        Lists available models in LM Studio.
    

    .EXAMPLE
        Invoke-LMStudio serve
        Starts the LM Studio server.
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
        else {
            $userHome = if (Get-Command Get-UserHome -ErrorAction SilentlyContinue) {
                Get-UserHome
            }
            elseif ($env:HOME) {
                $env:HOME
            }
            elseif ($env:USERPROFILE) {
                $env:USERPROFILE
            }
            else {
                $null
            }

            $lmsCandidates = @()
            if ($userHome) {
                $lmsCandidates += Join-Path $userHome '.lmstudio' 'bin' 'lms'
                $lmsCandidates += Join-Path $userHome '.cache' 'lm-studio' 'bin' 'lms'
            }

            $runningOnWindows = $IsWindows -or $PSVersionTable.Platform -eq 'Win32NT'
            foreach ($candidate in $lmsCandidates) {
                if (-not $candidate) {
                    continue
                }

                $pathsToCheck = if ($runningOnWindows) {
                    @($candidate, "$candidate.exe")
                }
                else {
                    @($candidate)
                }

                foreach ($pathToCheck in $pathsToCheck) {
                    if (Test-Path -LiteralPath $pathToCheck) {
                        $lmsCmd = $pathToCheck
                        break
                    }
                }

                if ($lmsCmd) {
                    break
                }
            }
        }

        if (-not $lmsCmd) {
            Invoke-MissingToolWarning -ToolName 'lmstudio' -Tool 'lms'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'ai.lmstudio.invoke' -Context @{
                arguments = $Arguments
                command   = $lmsCmd
            } -ScriptBlock {
                & $lmsCmd $Arguments 2>&1
            }
        }
        else {
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
    }

    Set-AgentModeFunction -Name 'Invoke-LMStudio' -Body ${function:Invoke-LMStudio}
    if (-not (Get-Alias lms -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'lms' -Target 'Invoke-LMStudio'
        }
        else {
            Set-AgentModeAlias -Name 'lms' -Target 'Invoke-LMStudio'
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
    

    .OUTPUTS
        System.String. Output from KoboldCpp execution.

    .EXAMPLE
        Invoke-KoboldCpp --help
        Shows KoboldCpp help.
    

    .EXAMPLE
        Start-KoboldCppServer -Model "llama-2-7b.gguf"
        Starts KoboldCpp server with a specific model.
    #>
    function Invoke-KoboldCpp {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'koboldcpp')) {
            Invoke-MissingToolWarning -ToolName 'koboldcpp'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'ai.koboldcpp.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & koboldcpp $Arguments 2>&1
            }
        }
        else {
            try {
                $result = & koboldcpp $Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run koboldcpp: $($_.Exception.Message)"
                return $null
            }
        }
    }

    Set-AgentModeFunction -Name 'Invoke-KoboldCpp' -Body ${function:Invoke-KoboldCpp}
    if (-not (Get-Alias koboldcpp -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'koboldcpp' -Target 'Invoke-KoboldCpp'
        }
        else {
            Set-AgentModeAlias -Name 'koboldcpp' -Target 'Invoke-KoboldCpp'
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
    

    .OUTPUTS
        System.String. Output from Llamafile execution.

    .EXAMPLE
        Invoke-Llamafile --help
        Shows Llamafile help.
    

    .EXAMPLE
        Invoke-Llamafile -Model "mistral-7b-instruct-v0.2.Q4_K_M.llamafile" -Prompt "Hello, world!"
        Runs a prompt with a specific llamafile model.
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
            Invoke-MissingToolWarning -ToolName 'llamafile'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'ai.llamafile.invoke' -Context @{
                arguments  = $Arguments
                model      = $Model
                has_prompt = (-not [string]::IsNullOrWhiteSpace($Prompt))
            } -ScriptBlock {
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
                & llamafile $cmdArgs 2>&1
            }
        }
        else {
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
    }

    Set-AgentModeFunction -Name 'Invoke-Llamafile' -Body ${function:Invoke-Llamafile}
    if (-not (Get-Alias llamafile -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'llamafile' -Target 'Invoke-Llamafile'
        }
        else {
            Set-AgentModeAlias -Name 'llamafile' -Target 'Invoke-Llamafile'
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
    

    .OUTPUTS
        System.String. Output from llama.cpp execution.

    .EXAMPLE
        Invoke-LlamaCpp --help
        Shows llama.cpp help.
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
            Invoke-MissingToolWarning -ToolName 'llama-cpp'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'ai.llamacpp.invoke' -Context @{
                arguments = $Arguments
                command   = $llamaCmd
            } -ScriptBlock {
                & $llamaCmd $Arguments 2>&1
            }
        }
        else {
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
    }

    Set-AgentModeFunction -Name 'Invoke-LlamaCpp' -Body ${function:Invoke-LlamaCpp}
    if (-not (Get-Alias llama-cpp -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'llama-cpp' -Target 'Invoke-LlamaCpp'
        }
        else {
            Set-AgentModeAlias -Name 'llama-cpp' -Target 'Invoke-LlamaCpp'
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
    

    .OUTPUTS
        System.String. Output from ComfyUI CLI execution.

    .EXAMPLE
        Invoke-ComfyUI install
        Installs ComfyUI.
    

    .EXAMPLE
        Invoke-ComfyUI launch
        Launches ComfyUI server.
    

    .EXAMPLE
        Invoke-ComfyUI node install custom-node-name
        Installs a custom node.
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
            Invoke-MissingToolWarning -ToolName 'comfy-cli' -ToolType 'python-package' -Tool 'comfy'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'ai.comfyui.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & comfy $Arguments 2>&1
            }
        }
        else {
            try {
                $result = & comfy $Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run comfy: $($_.Exception.Message)"
                return $null
            }
        }
    }

    Set-AgentModeFunction -Name 'Invoke-ComfyUI' -Body ${function:Invoke-ComfyUI}
    if (-not (Get-Alias comfy -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'comfy' -Target 'Invoke-ComfyUI'
        }
        else {
            Set-AgentModeAlias -Name 'comfy' -Target 'Invoke-ComfyUI'
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
