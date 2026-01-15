# ===============================================
# ConversionBase.ps1
# Base module for format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Base module providing common patterns for format conversion utilities.

.DESCRIPTION
    Extracts common patterns from conversion modules (data, document, media) to reduce duplication.
    Provides helper functions that conversion-specific modules can use or extend.
    
    Common Patterns:
    1. Input file validation
    2. Tool availability checking
    3. Output path generation
    4. Command execution with error handling
    5. Exit code validation
    6. Error message formatting

.NOTES
    This is a base module. Conversion-specific modules should use these functions
    or extend them with format-specific logic.
#>

try {
    # Idempotency check
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'conversion-base') { return }
    }

    # ===============================================
    # Invoke-FormatConversion - Main conversion helper
    # ===============================================

    <#
    .SYNOPSIS
        Executes a format conversion with standardized validation and error handling.
    
    .DESCRIPTION
        Provides a standardized way to execute format conversions with:
        - Input file validation
        - Tool availability checking
        - Output path generation
        - Command execution with error capture
        - Exit code validation
        - Comprehensive error handling
    
    .PARAMETER InputPath
        Path to the input file to convert.
    
    .PARAMETER OutputPath
        Optional path for the output file. If not provided, will be generated from InputPath.
    
    .PARAMETER ToolCommand
        Name of the conversion tool command (e.g., 'pandoc', 'ffmpeg', 'magick').
    
    .PARAMETER ToolArguments
        Array of arguments to pass to the tool command.
    
    .PARAMETER OutputExtension
        File extension for output file (e.g., '.html', '.pdf'). Used if OutputPath not provided.
    
    .PARAMETER InputExtension
        File extension of input file (e.g., '.md', '.jpg'). Used for output path generation.
    
    .PARAMETER InstallHint
        Installation hint for missing tool warning.
    
    .PARAMETER ErrorContext
        Context string for error messages (e.g., "Markdown to HTML conversion").
    
    .PARAMETER ValidateOutput
        If specified, validates that output file was created after conversion.
    
    .EXAMPLE
        Invoke-FormatConversion -InputPath 'document.md' `
            -ToolCommand 'pandoc' `
            -ToolArguments @('-o', 'output.html') `
            -OutputExtension '.html' `
            -InputExtension '.md' `
            -ErrorContext 'Markdown to HTML conversion'
        
        Converts Markdown to HTML using pandoc.
    
    .OUTPUTS
        System.Boolean. True if conversion successful, false otherwise.
    #>
    function Invoke-FormatConversion {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$InputPath,

            [string]$OutputPath = $null,

            [Parameter(Mandatory = $true)]
            [string]$ToolCommand,

            [Parameter(Mandatory = $true)]
            [string[]]$ToolArguments,

            [string]$OutputExtension = $null,

            [string]$InputExtension = $null,

            [string]$InstallHint = $null,

            [string]$ErrorContext = $null,

            [switch]$ValidateOutput
        )

        # Validate input path
        if ([string]::IsNullOrWhiteSpace($InputPath)) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.ArgumentException]::new("InputPath parameter is required"),
                    'InvalidParameter',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $null
                )
                Write-StructuredError -ErrorRecord $errorRecord -OperationName "conversion.validate" -Context @{
                    tool_command = $ToolCommand
                    error_context = $ErrorContext
                }
            }
            else {
                Write-Error "InputPath parameter is required"
            }
            return $false
        }

        if (-not (Test-Path -LiteralPath $InputPath -ErrorAction SilentlyContinue)) {
            $context = if ($ErrorContext) { "${ErrorContext}: " } else { "" }
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.IO.FileNotFoundException]::new("Input file not found: $InputPath"),
                    'FileNotFound',
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $InputPath
                )
                Write-StructuredError -ErrorRecord $errorRecord -OperationName "conversion.validate" -Context @{
                    input_path = $InputPath
                    tool_command = $ToolCommand
                    error_context = $ErrorContext
                }
            }
            else {
                Write-Error "${context}Input file not found: $InputPath"
            }
            return $false
        }

        # Check tool availability
        if (-not (Test-CachedCommand $ToolCommand)) {
            $hint = if ($InstallHint) { $InstallHint } else { "Install $ToolCommand to use this conversion" }
            Write-MissingToolWarning -Tool $ToolCommand -InstallHint $hint
            return $false
        }

        # Generate output path if not provided
        if ([string]::IsNullOrWhiteSpace($OutputPath)) {
            if ($OutputExtension) {
                $InputExtension = if ($InputExtension) { $InputExtension } else { [System.IO.Path]::GetExtension($InputPath) }
                $escapedExt = [regex]::Escape($InputExtension)
                $OutputPath = $InputPath -replace "${escapedExt}$", $OutputExtension
            }
            else {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        [System.ArgumentException]::new("OutputPath or OutputExtension must be provided"),
                        'InvalidParameter',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $null
                    )
                    Write-StructuredError -ErrorRecord $errorRecord -OperationName "conversion.validate" -Context @{
                        input_path = $InputPath
                        tool_command = $ToolCommand
                        error_context = $ErrorContext
                    }
                }
                else {
                    Write-Error "OutputPath or OutputExtension must be provided"
                }
                return $false
            }
        }

        # Execute conversion with wide event tracking
        $operationName = if ($ErrorContext) { "conversion.$($ErrorContext.ToLower().Replace(' ', '.'))" } else { "conversion.execute" }
        
        try {
            $result = if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                Invoke-WithWideEvent -OperationName $operationName -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    tool_command = $ToolCommand
                    tool_arguments = $ToolArguments -join ' '
                    error_context = $ErrorContext
                    validate_output = $ValidateOutput.IsPresent
                } -ScriptBlock {
                    $errorOutput = & $ToolCommand @ToolArguments 2>&1
                    $exitCode = $LASTEXITCODE

                    if ($exitCode -ne 0) {
                        $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                        $errorMsg = "${ToolCommand} failed with exit code ${exitCode}. Error: ${errorText}"
                        throw [System.InvalidOperationException]::new($errorMsg)
                    }

                    # Validate output if requested
                    if ($ValidateOutput) {
                        if (-not (Test-Path -LiteralPath $OutputPath -ErrorAction SilentlyContinue)) {
                            throw [System.IO.FileNotFoundException]::new("Output file was not created: ${OutputPath}")
                        }
                    }

                    return $true
                }
            }
            else {
                # Fallback: execute without wide event tracking
                $errorOutput = & $ToolCommand @ToolArguments 2>&1
                $exitCode = $LASTEXITCODE

                if ($exitCode -ne 0) {
                    $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                    $errorMsg = "${ToolCommand} failed with exit code ${exitCode}. Error: ${errorText}"
                    throw [System.InvalidOperationException]::new($errorMsg)
                }

                # Validate output if requested
                if ($ValidateOutput) {
                    if (-not (Test-Path -LiteralPath $OutputPath -ErrorAction SilentlyContinue)) {
                        throw [System.IO.FileNotFoundException]::new("Output file was not created: ${OutputPath}")
                    }
                }

                return $true
            }

            return $result
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName $operationName -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    tool_command = $ToolCommand
                    tool_arguments = $ToolArguments -join ' '
                    error_context = $ErrorContext
                    validate_output = $ValidateOutput.IsPresent
                } -StatusCode $LASTEXITCODE
            }
            elseif (Get-Command Handle-FragmentError -ErrorAction SilentlyContinue) {
                Handle-FragmentError -ErrorRecord $_ -Context "Conversion: $ErrorContext"
            }
            else {
                $context = if ($ErrorContext) { "${ErrorContext}: " } else { "" }
                Write-Error "${context}Failed to execute conversion: $($_.Exception.Message)"
            }
            return $false
        }
    }

    # ===============================================
    # Test-ConversionToolAvailable - Tool availability check
    # ===============================================

    <#
    .SYNOPSIS
        Tests if a conversion tool is available.
    
    .DESCRIPTION
        Checks for conversion tool availability with optional installation hint.
    
    .PARAMETER ToolCommand
        Name of the tool command to check.
    
    .PARAMETER InstallHint
        Installation hint to display if tool is missing.
    
    .OUTPUTS
        System.Boolean. True if tool is available, false otherwise.
    #>
    function Test-ConversionToolAvailable {
        [CmdletBinding()]
        [OutputType([bool])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ToolCommand,

            [string]$InstallHint = $null
        )

        $available = Test-CachedCommand $ToolCommand

        if (-not $available -and $InstallHint) {
            Write-MissingToolWarning -Tool $ToolCommand -InstallHint $InstallHint
        }

        return $available
    }

    # ===============================================
    # Get-OutputPathFromInput - Output path generation
    # ===============================================

    <#
    .SYNOPSIS
        Generates an output path from an input path by replacing the extension.
    
    .DESCRIPTION
        Creates an output file path by replacing the input file's extension with a new extension.
    
    .PARAMETER InputPath
        Path to the input file.
    
    .PARAMETER OutputExtension
        New extension for the output file (e.g., '.html', '.pdf').
    
    .PARAMETER InputExtension
        Optional input extension to replace. If not provided, uses file's actual extension.
    
    .EXAMPLE
        Get-OutputPathFromInput -InputPath 'document.md' -OutputExtension '.html'
        
        Returns 'document.html'.
    
    .OUTPUTS
        System.String. Generated output path.
    #>
    function Get-OutputPathFromInput {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$InputPath,

            [Parameter(Mandatory = $true)]
            [string]$OutputExtension,

            [string]$InputExtension = $null
        )

        if ([string]::IsNullOrWhiteSpace($InputPath)) {
            return $null
        }

        $inputExt = if ($InputExtension) { $InputExtension } else { [System.IO.Path]::GetExtension($InputPath) }
        
        if ([string]::IsNullOrWhiteSpace($inputExt)) {
            # No extension on input, just append output extension
            return "$InputPath$OutputExtension"
        }

        return $InputPath -replace [regex]::Escape($inputExt) + '$', $OutputExtension
    }

    # Register functions
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Invoke-FormatConversion' -Body ${function:Invoke-FormatConversion}
        Set-AgentModeFunction -Name 'Test-ConversionToolAvailable' -Body ${function:Test-ConversionToolAvailable}
        Set-AgentModeFunction -Name 'Get-OutputPathFromInput' -Body ${function:Get-OutputPathFromInput}
    }
    else {
        Set-Item -Path Function:Invoke-FormatConversion -Value ${function:Invoke-FormatConversion} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Test-ConversionToolAvailable -Value ${function:Test-ConversionToolAvailable} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-OutputPathFromInput -Value ${function:Get-OutputPathFromInput} -Force -ErrorAction SilentlyContinue
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'conversion-base'
    }
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName "conversion-base.load" -Context @{
            fragment = 'conversion-base'
            fragment_type = 'base-module'
        }
    }
    elseif (Get-Command Handle-FragmentError -ErrorAction SilentlyContinue) {
        Handle-FragmentError -ErrorRecord $_ -Context "Fragment: conversion-base"
    }
    elseif (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: conversion-base" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load conversion-base fragment: $($_.Exception.Message)"
    }
}
