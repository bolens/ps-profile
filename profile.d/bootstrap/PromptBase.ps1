# ===============================================
# PromptBase.ps1
# Base module for prompt framework initialization
# ===============================================

<#
.SYNOPSIS
    Base module providing common patterns for prompt framework initialization.

.DESCRIPTION
    Extracts common patterns from prompt initialization (Starship, Oh-My-Posh, etc.) to reduce duplication.
    Provides helper functions that prompt-specific modules can use or extend.
    
    Common Patterns:
    1. Command availability checking
    2. Initialization script execution
    3. Fallback prompt handling
    4. VS Code integration
    5. Error handling and recovery

.NOTES
    This is a base module. Prompt-specific modules (starship.ps1, oh-my-posh.ps1)
    should use these functions or extend them with framework-specific logic.
#>

try {
    # Idempotency check
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'prompt-base') { return }
    }

    # ===============================================
    # Initialize-PromptFramework - Main initialization helper
    # ===============================================

    <#
    .SYNOPSIS
        Initializes a prompt framework with standardized error handling and fallback.
    
    .DESCRIPTION
        Provides a standardized way to initialize prompt frameworks with:
        - Command availability checking
        - Initialization script execution
        - Automatic fallback to alternative prompt
        - Error handling and recovery
    
    .PARAMETER FrameworkName
        Name of the prompt framework (e.g., 'Starship', 'OhMyPosh').
    
    .PARAMETER CommandName
        Name of the CLI command (e.g., 'starship', 'oh-my-posh').
    
    .PARAMETER InitScript
        Script block that performs the initialization.
        Should handle all framework-specific setup.
    
    .PARAMETER FallbackPrompt
        Optional script block for fallback prompt initialization.
        Called if command is not available or initialization fails.
    
    .PARAMETER CheckInitialized
        Optional script block to check if framework is already initialized.
        Should return $true if already initialized, $false otherwise.
    
    .PARAMETER InstallHint
        Installation hint for missing tool warning.
    
    .EXAMPLE
        Initialize-PromptFramework -FrameworkName 'Starship' -CommandName 'starship' `
            -InitScript { Invoke-StarshipInit } `
            -FallbackPrompt { Initialize-SmartPrompt } `
            -CheckInitialized { Test-StarshipInitialized }
        
        Initializes Starship with fallback to smart prompt.
    
    .OUTPUTS
        System.Boolean. True if initialization successful, false otherwise.
    #>
    function Initialize-PromptFramework {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$FrameworkName,

            [Parameter(Mandatory = $true)]
            [string]$CommandName,

            [Parameter(Mandatory = $true)]
            [scriptblock]$InitScript,

            [scriptblock]$FallbackPrompt = $null,

            [scriptblock]$CheckInitialized = $null,

            [string]$InstallHint = $null
        )

        # Check if already initialized
        if ($CheckInitialized) {
            try {
                $alreadyInitialized = & $CheckInitialized
                if ($alreadyInitialized) {
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Host "$FrameworkName already initialized" -ForegroundColor Cyan
                    }
                    return $true
                }
            }
            catch {
                # If check fails, proceed with initialization
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "$FrameworkName initialization check failed: $($_.Exception.Message)"
                }
            }
        }

        # Check command availability
        if (-not (Test-CachedCommand $CommandName)) {
            if ($env:PS_PROFILE_DEBUG) {
                $hint = if ($InstallHint) { " $InstallHint" } else { "" }
                Write-Host "$FrameworkName not found, using fallback prompt$hint" -ForegroundColor Yellow
            }
            elseif ($InstallHint) {
                Write-MissingToolWarning -Tool $CommandName -InstallHint $InstallHint
            }

            if ($FallbackPrompt) {
                try {
                    & $FallbackPrompt
                    return $false
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        if (Get-Command Handle-FragmentError -ErrorAction SilentlyContinue) {
                            Handle-FragmentError -ErrorRecord $_ -Context "Fragment: $FrameworkName (fallback prompt)"
                        }
                        else {
                            Write-Verbose "Fallback prompt failed: $($_.Exception.Message)"
                        }
                    }
                }
            }
            return $false
        }

        # Execute initialization with wide event tracking
        $operationName = "prompt.$($FrameworkName.ToLower()).initialize"
        
        try {
            $result = if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                Invoke-WithWideEvent -OperationName $operationName -Context @{
                    framework_name = $FrameworkName
                    command_name   = $CommandName
                    has_fallback   = $FallbackPrompt -ne $null
                    install_hint   = $InstallHint
                } -ScriptBlock {
                    if ($env:PS_PROFILE_DEBUG) {
                        $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
                        if ($cmd) {
                            Write-Host "$FrameworkName found at: $($cmd.Source)" -ForegroundColor Green
                        }
                    }

                    & $InitScript

                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Host "$FrameworkName prompt initialized successfully" -ForegroundColor Green
                    }

                    return $true
                }
            }
            else {
                # Fallback: execute without wide event tracking
                if ($env:PS_PROFILE_DEBUG) {
                    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
                    if ($cmd) {
                        Write-Host "$FrameworkName found at: $($cmd.Source)" -ForegroundColor Green
                    }
                }

                & $InitScript

                if ($env:PS_PROFILE_DEBUG) {
                    Write-Host "$FrameworkName prompt initialized successfully" -ForegroundColor Green
                }

                return $true
            }

            return $result
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName $operationName -Context @{
                    framework_name = $FrameworkName
                    command_name   = $CommandName
                    has_fallback   = $FallbackPrompt -ne $null
                    install_hint   = $InstallHint
                }
            }
            elseif (Get-Command Handle-FragmentError -ErrorAction SilentlyContinue) {
                Handle-FragmentError -ErrorRecord $_ -Context "Fragment: $FrameworkName (initialization)"
            }
            else {
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "$FrameworkName initialization failed: $($_.Exception.Message)"
                }
            }

            # Try fallback if initialization failed
            if ($FallbackPrompt) {
                try {
                    & $FallbackPrompt
                }
                catch {
                    if ($env:PS_PROFILE_DEBUG) {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName "$operationName.fallback" -Context @{
                                framework_name     = $FrameworkName
                                fallback_attempted = $true
                            }
                        }
                        else {
                            Write-Verbose "Fallback prompt also failed: $($_.Exception.Message)"
                        }
                    }
                }
            }

            return $false
        }
    }

    # ===============================================
    # Test-PromptCommandAvailable - Command availability check
    # ===============================================

    <#
    .SYNOPSIS
        Tests if a prompt framework command is available.
    
    .DESCRIPTION
        Checks for prompt framework command availability with optional installation hint.
    
    .PARAMETER CommandName
        Name of the command to check.
    
    .PARAMETER InstallHint
        Installation hint to display if command is missing.
    
    .OUTPUTS
        System.Boolean. True if command is available, false otherwise.
    #>
    function Test-PromptCommandAvailable {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$CommandName,

            [string]$InstallHint = $null
        )

        $available = Test-CachedCommand $CommandName

        if (-not $available -and $InstallHint) {
            Write-MissingToolWarning -Tool $CommandName -InstallHint $InstallHint
        }

        return $available
    }

    # Register functions
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Initialize-PromptFramework' -Body ${function:Initialize-PromptFramework}
        Set-AgentModeFunction -Name 'Test-PromptCommandAvailable' -Body ${function:Test-PromptCommandAvailable}
    }
    else {
        Set-Item -Path Function:Initialize-PromptFramework -Value ${function:Initialize-PromptFramework} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Test-PromptCommandAvailable -Value ${function:Test-PromptCommandAvailable} -Force -ErrorAction SilentlyContinue
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'prompt-base'
    }
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        $context = @{
            fragment      = 'prompt-base'
            fragment_type = 'base-module'
        }
        Write-StructuredError -ErrorRecord $_ -OperationName "prompt-base.load" -Context $context
    }
    elseif (Get-Command Handle-FragmentError -ErrorAction SilentlyContinue) {
        Handle-FragmentError -ErrorRecord $_ -Context "Fragment: prompt-base"
    }
    elseif (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: prompt-base" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load prompt-base fragment: $($_.Exception.Message)"
    }
}
