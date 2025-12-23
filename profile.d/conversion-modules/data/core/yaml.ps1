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
        try {
            if (-not $fileArgs -or $fileArgs.Count -eq 0) {
                throw "File path parameter is required"
            }
            
            $resolvedPath = Resolve-Path @fileArgs -ErrorAction Stop | Select-Object -ExpandProperty Path
            if (-not ($resolvedPath -and -not [string]::IsNullOrWhiteSpace($resolvedPath) -and (Test-Path -LiteralPath $resolvedPath))) {
                throw "Input file not found: $resolvedPath"
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
            
            # Execute with error capture
            $errorOutput = & yq eval -o=json '.' $resolvedPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                return $errorOutput
            }
            
            # Build error message
            if (-not $errorOutput) {
                Write-Error "yq command failed with exit code $exitCode : Unknown error (no output from yq)" -ErrorAction SilentlyContinue
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
            Write-Error "yq command failed with exit code $exitCode : $errorMessage" -ErrorAction SilentlyContinue
            return $null
        }
        catch {
            Write-Error "Failed to convert YAML to JSON: $($_.Exception.Message)" -ErrorAction SilentlyContinue
            return $null
        }
    } -Force

    # JSON to YAML
    Set-Item -Path Function:Global:_ConvertTo-Yaml -Value {
        param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
        try {
            if (-not $fileArgs -or $fileArgs.Count -eq 0) {
                throw "File path parameter is required"
            }
            
            $resolvedPath = Resolve-Path @fileArgs -ErrorAction Stop | Select-Object -ExpandProperty Path
            if (-not ($resolvedPath -and -not [string]::IsNullOrWhiteSpace($resolvedPath) -and (Test-Path -LiteralPath $resolvedPath))) {
                throw "Input file not found: $resolvedPath"
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
            
            # Execute with error capture
            $errorOutput = & yq eval -p json -o yaml '.' $resolvedPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                return $errorOutput -join "`n"
            }
            
            # Build error message
            if (-not $errorOutput) {
                Write-Error "yq command failed with exit code $exitCode : Unknown error (no output from yq)" -ErrorAction SilentlyContinue
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
            Write-Error "yq command failed with exit code $exitCode : $errorMessage" -ErrorAction SilentlyContinue
            return $null
        }
        catch {
            Write-Error "Failed to convert JSON to YAML: $($_.Exception.Message)" -ErrorAction SilentlyContinue
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
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertTo-Yaml @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert JSON to YAML: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name json-to-yaml -Value ConvertTo-Yaml -ErrorAction SilentlyContinue

