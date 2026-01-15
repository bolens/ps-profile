# ===============================================
# YAML format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes YAML format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for YAML format conversions.
    Supports bidirectional conversions between YAML and JSON.
    This function is called automatically by Initialize-FileConversion-CoreBasic.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires yq command-line tool.
#>
function Initialize-FileConversion-CoreBasicYaml {
    # YAML to JSON
    Set-Item -Path Function:Global:_ConvertFrom-Yaml -Value {
        param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.yaml.to-json] Starting conversion"
            }
            
            if (-not $fileArgs -or $fileArgs.Count -eq 0) {
                throw "File path parameter is required"
            }
            
            $resolvedPath = Resolve-Path @fileArgs -ErrorAction Stop | Select-Object -ExpandProperty Path
            if (-not ($resolvedPath -and -not [string]::IsNullOrWhiteSpace($resolvedPath) -and (Test-Path -LiteralPath $resolvedPath))) {
                throw "Input file not found: $resolvedPath"
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.yaml.to-json] Input path: $resolvedPath"
                $inputSize = if (Test-Path -LiteralPath $resolvedPath) { (Get-Item -LiteralPath $resolvedPath).Length } else { 0 }
                Write-Verbose "[conversion.yaml.to-json] Input file size: ${inputSize} bytes"
            }
            
            $yqCommand = Get-Command yq -ErrorAction SilentlyContinue
            if (-not $yqCommand) {
                $errorMessage = "yq command not found. Please install yq to use this conversion function."
                $errorMessage += "`nSuggestion: Install yq from https://github.com/mikefarah/yq or use a package manager (scoop, choco, winget)"
                throw $errorMessage
            }
            
            # Validate yq is executable
            try {
                $yqVersion = & yq --version 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "yq command exists but failed to execute (exit code: $LASTEXITCODE)"
                }
            }
            catch {
                throw "yq command found at '$($yqCommand.Source)' but is not executable: $($_.Exception.Message)"
            }
            
            $convStartTime = Get-Date
            # Execute with error capture
            $errorOutput = & yq eval -o=json '.' $resolvedPath 2>&1
            $exitCode = $LASTEXITCODE
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            if ($exitCode -eq 0) {
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.yaml.to-json] Conversion completed in ${convDuration}ms"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    $inputSize = if (Test-Path -LiteralPath $resolvedPath) { (Get-Item -LiteralPath $resolvedPath).Length } else { 0 }
                    $outputLength = if ($errorOutput) { ($errorOutput | Out-String).Length } else { 0 }
                    Write-Host "  [conversion.yaml.to-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputLength} characters" -ForegroundColor DarkGray
                }
                
                return $errorOutput
            }
            
            # Build error message
            if (-not $errorOutput) {
                $errorMsg = "yq command failed with exit code $exitCode : Unknown error (no output from yq)"
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    $inputSize = if (Test-Path -LiteralPath $resolvedPath) { (Get-Item -LiteralPath $resolvedPath).Length } else { 0 }
                    Write-StructuredError -ErrorRecord ([System.Management.Automation.ErrorRecord]::new(
                        [System.Exception]::new($errorMsg),
                        'YqCommandFailed',
                        [System.Management.Automation.ErrorCategory]::NotSpecified,
                        $null
                    )) -OperationName 'conversion.yaml.to-json' -Context @{
                        input_path = $resolvedPath
                        input_size_bytes = $inputSize
                        yq_exit_code = $exitCode
                    }
                }
                else {
                    Write-Error $errorMsg -ErrorAction SilentlyContinue
                }
                return $null
            }
            
            # Filter out warnings
            $filteredOutput = $errorOutput | Where-Object { $_ -notmatch '^WARNING:' }
            $errorMessage = if ($filteredOutput) {
                $filteredOutput -join "`n"
            }
            else {
                $errorOutput -join "`n"
            }
            
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if (Test-Path -LiteralPath $resolvedPath) { (Get-Item -LiteralPath $resolvedPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord ([System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new("yq command failed with exit code $exitCode : $errorMessage"),
                    'YqCommandFailed',
                    [System.Management.Automation.ErrorCategory]::NotSpecified,
                    $null
                )) -OperationName 'conversion.yaml.to-json' -Context @{
                    input_path = $resolvedPath
                    input_size_bytes = $inputSize
                    yq_exit_code = $exitCode
                    yq_error_output = $errorMessage
                }
            }
            else {
                Write-Error "yq command failed with exit code $exitCode : $errorMessage" -ErrorAction SilentlyContinue
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.yaml.to-json] yq exit code: $exitCode"
            }
            
            return $null
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $resolvedPath = if ($fileArgs -and $fileArgs.Count -gt 0) {
                    try { (Resolve-Path @fileArgs -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path) } catch { $fileArgs[0] }
                } else { $null }
                $inputSize = if ($resolvedPath -and (Test-Path -LiteralPath $resolvedPath)) { (Get-Item -LiteralPath $resolvedPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.yaml.to-json' -Context @{
                    input_path = $resolvedPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert YAML to JSON: $($_.Exception.Message)" -ErrorAction SilentlyContinue
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.yaml.to-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.yaml.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            return $null
        }
    } -Force

    # JSON to YAML
    Set-Item -Path Function:Global:_ConvertTo-Yaml -Value {
        param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.yaml.from-json] Starting conversion"
            }
            
            if (-not $fileArgs -or $fileArgs.Count -eq 0) {
                throw "File path parameter is required"
            }
            
            $resolvedPath = Resolve-Path @fileArgs -ErrorAction Stop | Select-Object -ExpandProperty Path
            if (-not ($resolvedPath -and -not [string]::IsNullOrWhiteSpace($resolvedPath) -and (Test-Path -LiteralPath $resolvedPath))) {
                throw "Input file not found: $resolvedPath"
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.yaml.from-json] Input path: $resolvedPath"
                $inputSize = if (Test-Path -LiteralPath $resolvedPath) { (Get-Item -LiteralPath $resolvedPath).Length } else { 0 }
                Write-Verbose "[conversion.yaml.from-json] Input file size: ${inputSize} bytes"
            }
            
            $yqCommand = Get-Command yq -ErrorAction SilentlyContinue
            if (-not $yqCommand) {
                $errorMessage = "yq command not found. Please install yq to use this conversion function."
                $errorMessage += "`nSuggestion: Install yq from https://github.com/mikefarah/yq or use a package manager (scoop, choco, winget)"
                throw $errorMessage
            }
            
            # Validate yq is executable (reuse validation from above if already checked)
            if (-not $script:YqValidated) {
                try {
                    $yqVersion = & yq --version 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "yq command exists but failed to execute (exit code: $LASTEXITCODE)"
                    }
                    $script:YqValidated = $true
                }
                catch {
                    throw "yq command found at '$($yqCommand.Source)' but is not executable: $($_.Exception.Message)"
                }
            }
            
            $convStartTime = Get-Date
            # Execute with error capture
            $errorOutput = & yq eval -p json -o yaml '.' $resolvedPath 2>&1
            $exitCode = $LASTEXITCODE
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            if ($exitCode -eq 0) {
                $result = $errorOutput -join "`n"
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.yaml.from-json] Conversion completed in ${convDuration}ms"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    $inputSize = if (Test-Path -LiteralPath $resolvedPath) { (Get-Item -LiteralPath $resolvedPath).Length } else { 0 }
                    $outputLength = $result.Length
                    Write-Host "  [conversion.yaml.from-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputLength} characters" -ForegroundColor DarkGray
                }
                
                return $result
            }
            
            # Build error message
            if (-not $errorOutput) {
                $errorMsg = "yq command failed with exit code $exitCode : Unknown error (no output from yq)"
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    $inputSize = if (Test-Path -LiteralPath $resolvedPath) { (Get-Item -LiteralPath $resolvedPath).Length } else { 0 }
                    Write-StructuredError -ErrorRecord ([System.Management.Automation.ErrorRecord]::new(
                        [System.Exception]::new($errorMsg),
                        'YqCommandFailed',
                        [System.Management.Automation.ErrorCategory]::NotSpecified,
                        $null
                    )) -OperationName 'conversion.yaml.from-json' -Context @{
                        input_path = $resolvedPath
                        input_size_bytes = $inputSize
                        yq_exit_code = $exitCode
                    }
                }
                else {
                    Write-Error $errorMsg -ErrorAction SilentlyContinue
                }
                return $null
            }
            
            # Filter out warnings
            $filteredOutput = $errorOutput | Where-Object { $_ -notmatch '^WARNING:' }
            $errorMessage = if ($filteredOutput) {
                $filteredOutput -join "`n"
            }
            else {
                $errorOutput -join "`n"
            }
            
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if (Test-Path -LiteralPath $resolvedPath) { (Get-Item -LiteralPath $resolvedPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord ([System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new("yq command failed with exit code $exitCode : $errorMessage"),
                    'YqCommandFailed',
                    [System.Management.Automation.ErrorCategory]::NotSpecified,
                    $null
                )) -OperationName 'conversion.yaml.from-json' -Context @{
                    input_path = $resolvedPath
                    input_size_bytes = $inputSize
                    yq_exit_code = $exitCode
                    yq_error_output = $errorMessage
                }
            }
            else {
                Write-Error "yq command failed with exit code $exitCode : $errorMessage" -ErrorAction SilentlyContinue
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.yaml.from-json] yq exit code: $exitCode"
            }
            
            return $null
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $resolvedPath = if ($fileArgs -and $fileArgs.Count -gt 0) {
                    try { (Resolve-Path @fileArgs -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path) } catch { $fileArgs[0] }
                } else { $null }
                $inputSize = if ($resolvedPath -and (Test-Path -LiteralPath $resolvedPath)) { (Get-Item -LiteralPath $resolvedPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.yaml.from-json' -Context @{
                    input_path = $resolvedPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert JSON to YAML: $($_.Exception.Message)" -ErrorAction SilentlyContinue
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.yaml.from-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.yaml.from-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            return $null
        }
    } -Force
}

# Public functions and aliases
# Convert YAML to JSON
<#
.SYNOPSIS
    Converts YAML to JSON format.
.DESCRIPTION
    Transforms YAML input to JSON output using yq.
#>
function ConvertFrom-Yaml {
    param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Yaml @PSBoundParameters
}
Set-Alias -Name yaml-to-json -Value ConvertFrom-Yaml -ErrorAction SilentlyContinue

# Convert JSON to YAML
<#
.SYNOPSIS
    Converts JSON to YAML format.
.DESCRIPTION
    Transforms JSON input to YAML output using yq.
#>
function ConvertTo-Yaml {
    param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
    
    # Parse debug level once at function start
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        # Debug is enabled
    }
    
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertTo-Yaml @PSBoundParameters
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            $resolvedPath = if ($fileArgs -and $fileArgs.Count -gt 0) {
                try { (Resolve-Path @fileArgs -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path) } catch { $fileArgs[0] }
            } else { $null }
            $inputSize = if ($resolvedPath -and (Test-Path -LiteralPath $resolvedPath)) { (Get-Item -LiteralPath $resolvedPath).Length } else { 0 }
            Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.yaml.from-json' -Context @{
                input_path = $resolvedPath
                input_size_bytes = $inputSize
                error_type = $_.Exception.GetType().FullName
            }
        }
        else {
            Write-Error "Failed to convert JSON to YAML: $($_.Exception.Message)"
        }
        
        # Level 2: Error details
        if ($debugLevel -ge 2) {
            Write-Verbose "[conversion.yaml.from-json] Error type: $($_.Exception.GetType().FullName)"
        }
        
        # Level 3: Stack trace
        if ($debugLevel -ge 3) {
            Write-Host "  [conversion.yaml.from-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        }
        
        throw
    }
}
Set-Alias -Name json-to-yaml -Value ConvertTo-Yaml -ErrorAction SilentlyContinue

