# ===============================================
# HJSON (Human JSON) format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes HJSON format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for HJSON (Human JSON) format.
    HJSON is a more human-friendly format that allows:
    - Comments (// and /* */)
    - Unquoted keys
    - Trailing commas
    - More lenient whitespace
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    HJSON is a superset of JSON that is easier to read and write.
#>
function Initialize-FileConversion-Hjson {
    # Helper function to remove comments from HJSON
    Set-Item -Path Function:Global:_Remove-HjsonComments -Value {
        param([string]$HjsonContent)
        $result = ''
        $inString = $false
        $stringChar = $null
        $inBlockComment = $false
        $inLineComment = $false
        $i = 0
        while ($i -lt $HjsonContent.Length) {
            $char = $HjsonContent[$i]
            $nextChar = if ($i + 1 -lt $HjsonContent.Length) { $HjsonContent[$i + 1] } else { $null }
            
            # Handle string literals
            if (-not $inBlockComment -and -not $inLineComment) {
                if (($char -eq '"' -or $char -eq "'") -and ($i -eq 0 -or $HjsonContent[$i - 1] -ne '\')) {
                    if (-not $inString) {
                        $inString = $true
                        $stringChar = $char
                        $result += $char
                    }
                    elseif ($char -eq $stringChar) {
                        $inString = $false
                        $stringChar = $null
                        $result += $char
                    }
                    else {
                        $result += $char
                    }
                    $i++
                    continue
                }
            }
            
            if ($inString) {
                $result += $char
                $i++
                continue
            }
            
            # Handle block comments /* */
            if ($char -eq '/' -and $nextChar -eq '*' -and -not $inLineComment) {
                $inBlockComment = $true
                $i += 2
                continue
            }
            if ($inBlockComment -and $char -eq '*' -and $nextChar -eq '/') {
                $inBlockComment = $false
                $i += 2
                continue
            }
            if ($inBlockComment) {
                $i++
                continue
            }
            
            # Handle line comments //
            if ($char -eq '/' -and $nextChar -eq '/' -and -not $inBlockComment) {
                $inLineComment = $true
                $i += 2
                continue
            }
            if ($inLineComment -and $char -eq "`n") {
                $inLineComment = $false
                $result += $char
                $i++
                continue
            }
            if ($inLineComment) {
                $i++
                continue
            }
            
            $result += $char
            $i++
        }
        return $result
    } -Force

    # Helper function to normalize HJSON to JSON
    Set-Item -Path Function:Global:_Normalize-HjsonToJson -Value {
        param([string]$HjsonContent)
        # Remove comments first
        $content = _Remove-HjsonComments -HjsonContent $HjsonContent
        
        # Remove trailing commas (before } or ])
        $content = $content -replace ',\s*}', '}'
        $content = $content -replace ',\s*]', ']'
        
        # Add quotes to unquoted keys
        # This is a simplified approach - match key: pattern where key is not quoted
        $content = $content -replace '([{,]\s*)([a-zA-Z_][a-zA-Z0-9_]*)\s*:', '$1"$2":'
        
        return $content
    } -Force

    # HJSON to JSON
    Set-Item -Path Function:Global:_ConvertFrom-HjsonToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.hjson.to-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.hjson$', '.json'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.hjson.to-json] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $hjsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonContent = _Normalize-HjsonToJson -HjsonContent $hjsonContent
            
            # Validate by parsing
            $null = $jsonContent | ConvertFrom-Json -ErrorAction Stop
            
            Set-Content -LiteralPath $OutputPath -Value $jsonContent -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.hjson.to-json] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.hjson.to-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.hjson.to-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert HJSON to JSON: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.hjson.to-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.hjson.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # JSON to HJSON
    Set-Item -Path Function:Global:_ConvertTo-HjsonFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.hjson.from-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.hjson'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.hjson.from-json] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            # Convert to HJSON format (pretty-print and allow unquoted keys)
            $hjsonContent = $jsonObj | ConvertTo-Json -Depth 100
            
            # Remove quotes from simple keys (simplified - only for top-level)
            $hjsonContent = $hjsonContent -replace '"([a-zA-Z_][a-zA-Z0-9_]*)":', '$1:'
            
            Set-Content -LiteralPath $OutputPath -Value $hjsonContent -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.hjson.from-json] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.hjson.from-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.hjson.from-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert JSON to HJSON: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.hjson.from-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.hjson.from-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # HJSON to YAML
    Set-Item -Path Function:Global:_ConvertFrom-HjsonToYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.hjson.to-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.hjson$', '.yaml'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.hjson.to-yaml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert HJSON to JSON first, then JSON to YAML
            $tempJson = Join-Path $env:TEMP "hjson-temp-$(Get-Random).json"
            try {
                _ConvertFrom-HjsonToJson -InputPath $InputPath -OutputPath $tempJson
                if (Get-Command _ConvertFrom-JsonToYaml -ErrorAction SilentlyContinue) {
                    _ConvertFrom-JsonToYaml -InputPath $tempJson -OutputPath $OutputPath
                }
                else {
                    throw "YAML conversion not available. Ensure YAML conversion module is loaded."
                }
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.hjson.to-yaml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.hjson.to-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.hjson.to-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert HJSON to YAML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.hjson.to-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.hjson.to-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # YAML to HJSON
    Set-Item -Path Function:Global:_ConvertTo-HjsonFromYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.hjson.from-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(yaml|yml)$', '.hjson'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.hjson.from-yaml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert YAML to JSON first, then JSON to HJSON
            $tempJson = Join-Path $env:TEMP "hjson-temp-$(Get-Random).json"
            try {
                if (Get-Command _ConvertFrom-YamlToJson -ErrorAction SilentlyContinue) {
                    _ConvertFrom-YamlToJson -InputPath $InputPath -OutputPath $tempJson
                    _ConvertTo-HjsonFromJson -InputPath $tempJson -OutputPath $OutputPath
                }
                else {
                    throw "YAML conversion not available. Ensure YAML conversion module is loaded."
                }
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.hjson.from-yaml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.hjson.from-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.hjson.from-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert YAML to HJSON: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.hjson.from-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.hjson.from-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert HJSON to JSON
<#
.SYNOPSIS
    Converts an HJSON file to JSON format.
.DESCRIPTION
    Converts an HJSON (Human JSON) file to standard JSON format.
    Removes comments, normalizes unquoted keys, and removes trailing commas.
.PARAMETER InputPath
    The path to the HJSON file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.EXAMPLE
    ConvertFrom-HjsonToJson -InputPath 'config.hjson'
    
    Converts config.hjson to config.json.
.OUTPUTS
    System.String
    Returns the path to the output JSON file.
#>
function ConvertFrom-HjsonToJson {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-HjsonToJson @PSBoundParameters
}
Set-Alias -Name hjson-to-json -Value ConvertFrom-HjsonToJson -Scope Global -ErrorAction SilentlyContinue

# Convert JSON to HJSON
<#
.SYNOPSIS
    Converts a JSON file to HJSON format.
.DESCRIPTION
    Converts a standard JSON file to HJSON (Human JSON) format.
    Removes quotes from simple keys to make it more human-readable.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output HJSON file. If not specified, uses input path with .hjson extension.
.EXAMPLE
    ConvertTo-HjsonFromJson -InputPath 'config.json'
    
    Converts config.json to config.hjson.
.OUTPUTS
    System.String
    Returns the path to the output HJSON file.
#>
function ConvertTo-HjsonFromJson {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-HjsonFromJson @PSBoundParameters
}
Set-Alias -Name json-to-hjson -Value ConvertTo-HjsonFromJson -Scope Global -ErrorAction SilentlyContinue

# Convert HJSON to YAML
<#
.SYNOPSIS
    Converts an HJSON file to YAML format.
.DESCRIPTION
    Converts an HJSON file to YAML format via JSON intermediate conversion.
.PARAMETER InputPath
    The path to the HJSON file.
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
.EXAMPLE
    ConvertFrom-HjsonToYaml -InputPath 'config.hjson'
    
    Converts config.hjson to config.yaml.
.OUTPUTS
    System.String
    Returns the path to the output YAML file.
#>
function ConvertFrom-HjsonToYaml {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-HjsonToYaml @PSBoundParameters
}
Set-Alias -Name hjson-to-yaml -Value ConvertFrom-HjsonToYaml -Scope Global -ErrorAction SilentlyContinue

# Convert YAML to HJSON
<#
.SYNOPSIS
    Converts a YAML file to HJSON format.
.DESCRIPTION
    Converts a YAML file to HJSON format via JSON intermediate conversion.
.PARAMETER InputPath
    The path to the YAML file.
.PARAMETER OutputPath
    The path for the output HJSON file. If not specified, uses input path with .hjson extension.
.EXAMPLE
    ConvertTo-HjsonFromYaml -InputPath 'config.yaml'
    
    Converts config.yaml to config.hjson.
.OUTPUTS
    System.String
    Returns the path to the output HJSON file.
#>
function ConvertTo-HjsonFromYaml {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-HjsonFromYaml @PSBoundParameters
}
Set-Alias -Name yaml-to-hjson -Value ConvertTo-HjsonFromYaml -Scope Global -ErrorAction SilentlyContinue

