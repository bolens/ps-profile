# ===============================================
# JSONC (JSON with Comments) format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes JSONC format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for JSONC (JSON with Comments) format.
    JSONC is JSON with C-style comments (// and /* */) support.
    Commonly used in VS Code settings and configuration files.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    JSONC is a superset of JSON that allows comments for documentation.
#>
function Initialize-FileConversion-Jsonc {
    # Helper function to remove comments from JSONC
    Set-Item -Path Function:Global:_Remove-JsoncComments -Value {
        param([string]$JsoncContent)
        $result = ''
        $inString = $false
        $stringChar = $null
        $inBlockComment = $false
        $inLineComment = $false
        $i = 0
        while ($i -lt $JsoncContent.Length) {
            $char = $JsoncContent[$i]
            $nextChar = if ($i + 1 -lt $JsoncContent.Length) { $JsoncContent[$i + 1] } else { $null }
            
            # Handle string literals
            if (-not $inBlockComment -and -not $inLineComment) {
                if ($char -eq '"' -and ($i -eq 0 -or $JsoncContent[$i - 1] -ne '\')) {
                    if (-not $inString) {
                        $inString = $true
                        $stringChar = '"'
                        $result += $char
                    }
                    else {
                        $inString = $false
                        $stringChar = $null
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
            if ($inLineComment -and ($char -eq "`n" -or $char -eq "`r")) {
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

    # JSONC to JSON
    Set-Item -Path Function:Global:_ConvertFrom-JsoncToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.jsonc.to-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.jsonc$', '.json'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonc.to-json] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $jsoncContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonContent = _Remove-JsoncComments -JsoncContent $jsoncContent
            
            # Validate by parsing
            $null = $jsonContent | ConvertFrom-Json -ErrorAction Stop
            
            Set-Content -LiteralPath $OutputPath -Value $jsonContent -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonc.to-json] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.jsonc.to-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.jsonc.to-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert JSONC to JSON: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonc.to-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.jsonc.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # JSON to JSONC
    Set-Item -Path Function:Global:_ConvertTo-JsoncFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.jsonc.from-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.jsonc'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonc.from-json] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            # Convert to JSONC format (pretty-print JSON - comments would need to be added manually)
            $jsoncContent = $jsonObj | ConvertTo-Json -Depth 100
            
            Set-Content -LiteralPath $OutputPath -Value $jsoncContent -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonc.from-json] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.jsonc.from-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.jsonc.from-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert JSON to JSONC: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonc.from-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.jsonc.from-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # JSONC to YAML
    Set-Item -Path Function:Global:_ConvertFrom-JsoncToYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.jsonc.to-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.jsonc$', '.yaml'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonc.to-yaml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert JSONC to JSON first, then JSON to YAML
            $tempJson = Join-Path $env:TEMP "jsonc-temp-$(Get-Random).json"
            try {
                _ConvertFrom-JsoncToJson -InputPath $InputPath -OutputPath $tempJson
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
                Write-Verbose "[conversion.jsonc.to-yaml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.jsonc.to-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.jsonc.to-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert JSONC to YAML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonc.to-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.jsonc.to-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # YAML to JSONC
    Set-Item -Path Function:Global:_ConvertTo-JsoncFromYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.jsonc.from-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(yaml|yml)$', '.jsonc'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonc.from-yaml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert YAML to JSON first, then JSON to JSONC
            $tempJson = Join-Path $env:TEMP "jsonc-temp-$(Get-Random).json"
            try {
                if (Get-Command _ConvertFrom-YamlToJson -ErrorAction SilentlyContinue) {
                    _ConvertFrom-YamlToJson -InputPath $InputPath -OutputPath $tempJson
                    _ConvertTo-JsoncFromJson -InputPath $tempJson -OutputPath $OutputPath
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
                Write-Verbose "[conversion.jsonc.from-yaml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.jsonc.from-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.jsonc.from-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert YAML to JSONC: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonc.from-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.jsonc.from-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert JSONC to JSON
<#
.SYNOPSIS
    Converts a JSONC file to JSON format.
.DESCRIPTION
    Converts a JSONC (JSON with Comments) file to standard JSON format.
    Removes C-style comments (// and /* */) from the file.
.PARAMETER InputPath
    The path to the JSONC file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.EXAMPLE
    ConvertFrom-JsoncToJson -InputPath 'settings.jsonc'
    
    Converts settings.jsonc to settings.json.
.OUTPUTS
    System.String
    Returns the path to the output JSON file.
#>
function ConvertFrom-JsoncToJson {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-JsoncToJson @PSBoundParameters
}
Set-Alias -Name jsonc-to-json -Value ConvertFrom-JsoncToJson -Scope Global -ErrorAction SilentlyContinue

# Convert JSON to JSONC
<#
.SYNOPSIS
    Converts a JSON file to JSONC format.
.DESCRIPTION
    Converts a standard JSON file to JSONC format.
    Note: Comments are not automatically added - the output is valid JSONC without comments.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output JSONC file. If not specified, uses input path with .jsonc extension.
.EXAMPLE
    ConvertTo-JsoncFromJson -InputPath 'settings.json'
    
    Converts settings.json to settings.jsonc.
.OUTPUTS
    System.String
    Returns the path to the output JSONC file.
#>
function ConvertTo-JsoncFromJson {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-JsoncFromJson @PSBoundParameters
}
Set-Alias -Name json-to-jsonc -Value ConvertTo-JsoncFromJson -Scope Global -ErrorAction SilentlyContinue

# Convert JSONC to YAML
<#
.SYNOPSIS
    Converts a JSONC file to YAML format.
.DESCRIPTION
    Converts a JSONC file to YAML format via JSON intermediate conversion.
.PARAMETER InputPath
    The path to the JSONC file.
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
.EXAMPLE
    ConvertFrom-JsoncToYaml -InputPath 'settings.jsonc'
    
    Converts settings.jsonc to settings.yaml.
.OUTPUTS
    System.String
    Returns the path to the output YAML file.
#>
function ConvertFrom-JsoncToYaml {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-JsoncToYaml @PSBoundParameters
}
Set-Alias -Name jsonc-to-yaml -Value ConvertFrom-JsoncToYaml -Scope Global -ErrorAction SilentlyContinue

# Convert YAML to JSONC
<#
.SYNOPSIS
    Converts a YAML file to JSONC format.
.DESCRIPTION
    Converts a YAML file to JSONC format via JSON intermediate conversion.
.PARAMETER InputPath
    The path to the YAML file.
.PARAMETER OutputPath
    The path for the output JSONC file. If not specified, uses input path with .jsonc extension.
.EXAMPLE
    ConvertTo-JsoncFromYaml -InputPath 'settings.yaml'
    
    Converts settings.yaml to settings.jsonc.
.OUTPUTS
    System.String
    Returns the path to the output JSONC file.
#>
function ConvertTo-JsoncFromYaml {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-JsoncFromYaml @PSBoundParameters
}
Set-Alias -Name yaml-to-jsonc -Value ConvertTo-JsoncFromYaml -Scope Global -ErrorAction SilentlyContinue

