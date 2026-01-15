# ===============================================
# JSON format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes JSON format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for JSON format operations.
    Supports JSON pretty-printing.
    This function is called automatically by Initialize-FileConversion-CoreBasic.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-CoreBasicJson {
    # JSON pretty-print
    Set-Item -Path Function:Global:_Format-Json -Value {
        param(
            [Parameter(ValueFromPipeline = $true)]
            $InputObject,
            [Parameter(ValueFromRemainingArguments = $true)]
            $fileArgs
        )
        process {
            # Parse debug level once at function start
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                # Debug is enabled
            }
            
            $rawInput = $null
            $inputSource = 'pipeline'
            $inputPath = $null
            try {
                $formatStartTime = Get-Date
                
                if ($fileArgs) {
                    $inputSource = 'file'
                    $inputPath = $fileArgs[0]
                    
                    # Level 1: Basic operation start
                    if ($debugLevel -ge 1) {
                        Write-Verbose "[conversion.json.pretty-print] Starting JSON formatting from file: $inputPath"
                    }
                    
                    # Level 2: File context
                    if ($debugLevel -ge 2) {
                        $inputSize = if (Test-Path -LiteralPath $inputPath) { (Get-Item -LiteralPath $inputPath).Length } else { 0 }
                        Write-Verbose "[conversion.json.pretty-print] Input file size: ${inputSize} bytes"
                    }
                    
                    $rawInput = Get-Content -Raw -LiteralPath @fileArgs
                    $rawInput | ConvertFrom-Json -ErrorAction Stop | ConvertTo-Json -Depth 10
                }
                elseif ($PSBoundParameters.ContainsKey('InputObject') -and $null -ne $InputObject) {
                    $inputSource = 'object'
                    
                    # Level 1: Basic operation start
                    if ($debugLevel -ge 1) {
                        Write-Verbose "[conversion.json.pretty-print] Starting JSON formatting from object"
                    }
                    
                    # Level 2: Object context
                    if ($debugLevel -ge 2) {
                        $inputType = $InputObject.GetType().FullName
                        Write-Verbose "[conversion.json.pretty-print] Input object type: $inputType"
                    }
                    
                    $rawInput = $InputObject
                    $rawInput | ConvertFrom-Json -ErrorAction Stop | ConvertTo-Json -Depth 10
                }
                else {
                    $inputSource = 'pipeline'
                    
                    # Level 1: Basic operation start
                    if ($debugLevel -ge 1) {
                        Write-Verbose "[conversion.json.pretty-print] Starting JSON formatting from pipeline"
                    }
                    
                    $rawInput = $input | Out-String
                    if ([string]::IsNullOrWhiteSpace($rawInput)) {
                        return
                    }
                    
                    # Level 2: Pipeline context
                    if ($debugLevel -ge 2) {
                        $inputLength = $rawInput.Length
                        Write-Verbose "[conversion.json.pretty-print] Pipeline input length: ${inputLength} characters"
                    }
                    
                    $rawInput | ConvertFrom-Json -ErrorAction Stop | ConvertTo-Json -Depth 10
                }
                
                $formatDuration = ((Get-Date) - $formatStartTime).TotalMilliseconds
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.json.pretty-print] Formatting completed in ${formatDuration}ms"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    $outputLength = if ($rawInput) { $rawInput.Length } else { 0 }
                    Write-Host "  [conversion.json.pretty-print] Performance - Duration: ${formatDuration}ms, Input source: $inputSource, Input length: ${outputLength} characters" -ForegroundColor DarkGray
                }
            }
            catch {
                # Only show warning when not running in Pester tests
                if (-not (Get-Module -Name Pester -ErrorAction SilentlyContinue)) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Failed to pretty-print JSON" -OperationName 'conversion.json.pretty-print' -Context @{
                            error_message = $_.Exception.Message
                            error_type = $_.Exception.GetType().FullName
                            input_source = $inputSource
                            input_path = $inputPath
                            input_length = if ($rawInput) { $rawInput.Length } else { 0 }
                        } -Code 'JsonPrettyPrintFailed'
                    }
                    else {
                        Write-Warning "Failed to pretty-print JSON: $($_.Exception.Message)"
                    }
                }
                
                # Level 2: Error details
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.json.pretty-print] Error type: $($_.Exception.GetType().FullName)"
                    Write-Verbose "[conversion.json.pretty-print] Error message: $($_.Exception.Message)"
                }
                
                # Level 3: Stack trace
                if ($debugLevel -ge 3) {
                    Write-Host "  [conversion.json.pretty-print] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                }
                
                if ($null -ne $rawInput) {
                    Write-Output $rawInput
                }
            }
        }
    } -Force
}

# Public functions and aliases
# Pretty-print JSON
<#
.SYNOPSIS
    Pretty-prints JSON data.
.DESCRIPTION
    Formats JSON data with proper indentation and structure.
#>
function Format-Json {
    param([Parameter(ValueFromPipeline = $true)] $InputObject, [Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
    
    # Parse debug level once at function start
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        # Debug is enabled
    }
    
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        & "Global:_Format-Json" @PSBoundParameters
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.json.format' -Context @{
                has_file_args = ($null -ne $fileArgs)
                file_args_count = if ($fileArgs) { $fileArgs.Count } else { 0 }
                has_input_object = ($PSBoundParameters.ContainsKey('InputObject') -and $null -ne $InputObject)
            }
        }
        else {
            Write-Error "Failed to pretty-print JSON: $($_.Exception.Message)"
        }
        
        # Level 2: Error details
        if ($debugLevel -ge 2) {
            Write-Verbose "[conversion.json.format] Error type: $($_.Exception.GetType().FullName)"
        }
        
        # Level 3: Stack trace
        if ($debugLevel -ge 3) {
            Write-Host "  [conversion.json.format] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        }
        
        throw
    }
}
# Use Set-AgentModeAlias if available, otherwise Set-Alias in Global scope
if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'json-pretty' -Target 'Format-Json'
}
else {
    Set-Alias -Name json-pretty -Value Format-Json -Scope Global -ErrorAction SilentlyContinue
}

