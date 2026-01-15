# ===============================================
# .env file format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes .env file format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for .env file format conversions.
    .env files are used to store environment variables in key=value format.
    Supports conversions between .env and JSON, YAML, INI, and other formats.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    .env files support comments (lines starting with #) and multi-line values.
#>
function Initialize-FileConversion-Env {
    # Helper function to parse .env file
    Set-Item -Path Function:Global:_Parse-EnvFile -Value {
        param([string]$EnvContent)
        $result = @{}
        $lines = $EnvContent -split "`r?`n"
        $currentKey = $null
        $currentValue = ''
        
        foreach ($line in $lines) {
            $trimmedLine = $line.Trim()
            
            # Skip empty lines and comments
            if ([string]::IsNullOrWhiteSpace($trimmedLine) -or $trimmedLine.StartsWith('#')) {
                continue
            }
            
            # Check for key=value pair
            if ($trimmedLine -match '^([^=#]+)=(.*)$') {
                # Save previous key-value if exists
                if ($null -ne $currentKey) {
                    $result[$currentKey] = $currentValue.Trim()
                }
                
                $currentKey = $matches[1].Trim()
                $currentValue = $matches[2]
                
                # Remove quotes if present
                if ($currentValue.StartsWith('"') -and $currentValue.EndsWith('"')) {
                    $currentValue = $currentValue.Substring(1, $currentValue.Length - 2)
                }
                elseif ($currentValue.StartsWith("'") -and $currentValue.EndsWith("'")) {
                    $currentValue = $currentValue.Substring(1, $currentValue.Length - 2)
                }
            }
            else {
                # Continuation of previous value (multi-line)
                if ($null -ne $currentKey) {
                    $currentValue += "`n" + $line
                }
            }
        }
        
        # Save last key-value
        if ($null -ne $currentKey) {
            $result[$currentKey] = $currentValue.Trim()
        }
        
        return $result
    } -Force

    # .env to JSON
    Set-Item -Path Function:Global:_ConvertFrom-EnvToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.env.to-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.env$', '.json'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.to-json] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $envContent = Get-Content -LiteralPath $InputPath -Raw
            $envData = _Parse-EnvFile -EnvContent $envContent
            
            $jsonObj = [PSCustomObject]$envData
            $json = $jsonObj | ConvertTo-Json -Depth 100
            Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.to-json] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.env.to-json] Environment variables found: $($envData.Keys.Count)"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.env.to-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Variables: $($envData.Keys.Count)" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.env.to-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert .env to JSON: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.to-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.env.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # JSON to .env
    Set-Item -Path Function:Global:_ConvertTo-EnvFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.env.from-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.env'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.from-json] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            $envLines = @()
            $varCount = 0
            $jsonObj.PSObject.Properties | ForEach-Object {
                $key = $_.Name
                $value = $_.Value
                if ($null -eq $value) {
                    $value = ''
                }
                # Quote values that contain spaces or special characters
                if ($value -match '\s' -or $value -match '[#=]') {
                    $value = "`"$value`""
                }
                $envLines += "$key=$value"
                $varCount++
            }
            
            Set-Content -LiteralPath $OutputPath -Value ($envLines -join "`n") -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.from-json] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.env.from-json] Environment variables created: $varCount"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.env.from-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Variables: $varCount" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.env.from-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert JSON to .env: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.from-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.env.from-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # .env to YAML
    Set-Item -Path Function:Global:_ConvertFrom-EnvToYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.env.to-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.env$', '.yaml'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.to-yaml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert .env to JSON first, then JSON to YAML
            $tempJson = Join-Path $env:TEMP "env-temp-$(Get-Random).json"
            try {
                _ConvertFrom-EnvToJson -InputPath $InputPath -OutputPath $tempJson
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
                Write-Verbose "[conversion.env.to-yaml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.env.to-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.env.to-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert .env to YAML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.to-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.env.to-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # YAML to .env
    Set-Item -Path Function:Global:_ConvertTo-EnvFromYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.env.from-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(yaml|yml)$', '.env'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.from-yaml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert YAML to JSON first, then JSON to .env
            $tempJson = Join-Path $env:TEMP "env-temp-$(Get-Random).json"
            try {
                if (Get-Command _ConvertFrom-YamlToJson -ErrorAction SilentlyContinue) {
                    _ConvertFrom-YamlToJson -InputPath $InputPath -OutputPath $tempJson
                    _ConvertTo-EnvFromJson -InputPath $tempJson -OutputPath $OutputPath
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
                Write-Verbose "[conversion.env.from-yaml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.env.from-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.env.from-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert YAML to .env: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.from-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.env.from-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # .env to INI
    Set-Item -Path Function:Global:_ConvertFrom-EnvToIni -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.env.to-ini] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.env$', '.ini'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.to-ini] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $envContent = Get-Content -LiteralPath $InputPath -Raw
            $envData = _Parse-EnvFile -EnvContent $envContent
            
            $iniLines = @()
            $iniLines += '[env]'
            foreach ($key in $envData.Keys) {
                $value = $envData[$key]
                if ($null -eq $value) {
                    $value = ''
                }
                # Quote values that contain spaces or special characters
                if ($value -match '\s' -or $value -match '[#=;]') {
                    $value = "`"$value`""
                }
                $iniLines += "$key=$value"
            }
            
            Set-Content -LiteralPath $OutputPath -Value ($iniLines -join "`n") -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.to-ini] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.env.to-ini] Environment variables converted: $($envData.Keys.Count)"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.env.to-ini] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Variables: $($envData.Keys.Count)" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.env.to-ini' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert .env to INI: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.to-ini] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.env.to-ini] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # INI to .env
    Set-Item -Path Function:Global:_ConvertTo-EnvFromIni -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.env.from-ini] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ini$', '.env'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.from-ini] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert INI to JSON first, then JSON to .env
            $tempJson = Join-Path $env:TEMP "env-temp-$(Get-Random).json"
            try {
                if (Get-Command _ConvertFrom-IniToJson -ErrorAction SilentlyContinue) {
                    _ConvertFrom-IniToJson -InputPath $InputPath -OutputPath $tempJson
                    _ConvertTo-EnvFromJson -InputPath $tempJson -OutputPath $OutputPath
                }
                else {
                    throw "INI conversion not available. Ensure INI conversion module is loaded."
                }
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.from-ini] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.env.from-ini] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.env.from-ini' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert INI to .env: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.env.from-ini] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.env.from-ini] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert .env to JSON
<#
.SYNOPSIS
    Converts a .env file to JSON format.
.DESCRIPTION
    Converts a .env file (environment variables) to JSON format.
    Parses key=value pairs and converts them to a JSON object.
.PARAMETER InputPath
    The path to the .env file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.EXAMPLE
    ConvertFrom-EnvToJson -InputPath '.env'
    
    Converts .env to .env.json.
.OUTPUTS
    System.String
    Returns the path to the output JSON file.
#>
function ConvertFrom-EnvToJson {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-EnvToJson @PSBoundParameters
}
Set-Alias -Name env-to-json -Value ConvertFrom-EnvToJson -Scope Global -ErrorAction SilentlyContinue

# Convert JSON to .env
<#
.SYNOPSIS
    Converts a JSON file to .env format.
.DESCRIPTION
    Converts a JSON object to .env file format (key=value pairs).
    Each property in the JSON object becomes a key=value line in the .env file.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output .env file. If not specified, uses input path with .env extension.
.EXAMPLE
    ConvertTo-EnvFromJson -InputPath 'config.json'
    
    Converts config.json to config.env.
.OUTPUTS
    System.String
    Returns the path to the output .env file.
#>
function ConvertTo-EnvFromJson {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-EnvFromJson @PSBoundParameters
}
Set-Alias -Name json-to-env -Value ConvertTo-EnvFromJson -Scope Global -ErrorAction SilentlyContinue

# Convert .env to YAML
<#
.SYNOPSIS
    Converts a .env file to YAML format.
.DESCRIPTION
    Converts a .env file to YAML format via JSON intermediate conversion.
.PARAMETER InputPath
    The path to the .env file.
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
.EXAMPLE
    ConvertFrom-EnvToYaml -InputPath '.env'
    
    Converts .env to .env.yaml.
.OUTPUTS
    System.String
    Returns the path to the output YAML file.
#>
function ConvertFrom-EnvToYaml {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-EnvToYaml @PSBoundParameters
}
Set-Alias -Name env-to-yaml -Value ConvertFrom-EnvToYaml -Scope Global -ErrorAction SilentlyContinue

# Convert YAML to .env
<#
.SYNOPSIS
    Converts a YAML file to .env format.
.DESCRIPTION
    Converts a YAML file to .env format via JSON intermediate conversion.
.PARAMETER InputPath
    The path to the YAML file.
.PARAMETER OutputPath
    The path for the output .env file. If not specified, uses input path with .env extension.
.EXAMPLE
    ConvertTo-EnvFromYaml -InputPath 'config.yaml'
    
    Converts config.yaml to config.env.
.OUTPUTS
    System.String
    Returns the path to the output .env file.
#>
function ConvertTo-EnvFromYaml {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-EnvFromYaml @PSBoundParameters
}
Set-Alias -Name yaml-to-env -Value ConvertTo-EnvFromYaml -Scope Global -ErrorAction SilentlyContinue

# Convert .env to INI
<#
.SYNOPSIS
    Converts a .env file to INI format.
.DESCRIPTION
    Converts a .env file to INI format.
    All key-value pairs are placed in an [env] section.
.PARAMETER InputPath
    The path to the .env file.
.PARAMETER OutputPath
    The path for the output INI file. If not specified, uses input path with .ini extension.
.EXAMPLE
    ConvertFrom-EnvToIni -InputPath '.env'
    
    Converts .env to .env.ini.
.OUTPUTS
    System.String
    Returns the path to the output INI file.
#>
function ConvertFrom-EnvToIni {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-EnvToIni @PSBoundParameters
}
Set-Alias -Name env-to-ini -Value ConvertFrom-EnvToIni -Scope Global -ErrorAction SilentlyContinue

# Convert INI to .env
<#
.SYNOPSIS
    Converts an INI file to .env format.
.DESCRIPTION
    Converts an INI file to .env format via JSON intermediate conversion.
    All sections are flattened into key=value pairs.
.PARAMETER InputPath
    The path to the INI file.
.PARAMETER OutputPath
    The path for the output .env file. If not specified, uses input path with .env extension.
.EXAMPLE
    ConvertTo-EnvFromIni -InputPath 'config.ini'
    
    Converts config.ini to config.env.
.OUTPUTS
    System.String
    Returns the path to the output .env file.
#>
function ConvertTo-EnvFromIni {
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-EnvFromIni @PSBoundParameters
}
Set-Alias -Name ini-to-env -Value ConvertTo-EnvFromIni -Scope Global -ErrorAction SilentlyContinue

