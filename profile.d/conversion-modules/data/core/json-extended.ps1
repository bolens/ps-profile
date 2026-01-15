# ===============================================
# Extended JSON format conversion utilities
# JSON5, JSONL
# ===============================================

<#
.SYNOPSIS
    Initializes extended JSON format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for extended JSON formats: JSON5 and JSONL.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and json5 package for JSON5 conversions.
#>
function Initialize-FileConversion-CoreJsonExtended {
    # Ensure NodeJs module is imported (use repo root from bootstrap if available)
    if (-not (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Variable -Name 'RepoRoot' -Scope Script -ErrorAction SilentlyContinue) {
            $script:RepoRoot
        }
        elseif (Get-Variable -Name 'BootstrapRoot' -Scope Script -ErrorAction SilentlyContinue) {
            Split-Path -Parent $script:BootstrapRoot
        }
        else {
            Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        }
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'NodeJs.psm1'
        if ($nodeJsModulePath -and
            -not [string]::IsNullOrWhiteSpace($nodeJsModulePath) -and
            (Test-Path -LiteralPath $nodeJsModulePath)) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
        }
    }
    # JSON5 to JSON
    Set-Item -Path Function:Global:_ConvertFrom-Json5ToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.json5.to-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json5$', '.json'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.json5.to-json] Output path: $OutputPath"
            }
            
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use JSON5 conversions."
            }
            
            $nodeScript = @"
try {
    const JSON5 = require('json5');
    const fs = require('fs');
    const json5Content = fs.readFileSync(process.argv[2], 'utf8');
    const data = JSON5.parse(json5Content);
    const json = JSON.stringify(data, null, 2);
    fs.writeFileSync(process.argv[3], json);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: json5 package is not installed. Install it with: pnpm add -g json5');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "json5-parse-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            
            # Level 1: Conversion execution
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.json5.to-json] Executing Node.js conversion script"
            }
            
            $convStartTime = Get-Date
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $InputPath, $OutputPath
                $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed with exit code $LASTEXITCODE: $result"
                }
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.json5.to-json] Conversion completed in ${convDuration}ms"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                    $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                    Write-Host "  [conversion.json5.to-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $nodeAvailable = (Get-Command node -ErrorAction SilentlyContinue) -ne $null
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.json5.to-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    node_available = $nodeAvailable
                    node_exit_code = $LASTEXITCODE
                }
            }
            else {
                Write-Error "Failed to convert JSON5 to JSON: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.json5.to-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.json5.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # JSON to JSON5
    Set-Item -Path Function:Global:_ConvertTo-Json5FromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.json5.from-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.json5'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.json5.from-json] Output path: $OutputPath"
            }
            
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use JSON5 conversions."
            }
            
            $nodeScript = @"
try {
    const JSON5 = require('json5');
    const fs = require('fs');
    const jsonContent = fs.readFileSync(process.argv[2], 'utf8');
    const data = JSON.parse(jsonContent);
    const json5 = JSON5.stringify(data, null, 2);
    fs.writeFileSync(process.argv[3], json5);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: json5 package is not installed. Install it with: pnpm add -g json5');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "json5-stringify-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            
            # Level 1: Conversion execution
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.json5.from-json] Executing Node.js conversion script"
            }
            
            $convStartTime = Get-Date
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $InputPath, $OutputPath
                $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed with exit code $LASTEXITCODE: $result"
                }
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.json5.from-json] Conversion completed in ${convDuration}ms"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                    $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                    Write-Host "  [conversion.json5.from-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $nodeAvailable = (Get-Command node -ErrorAction SilentlyContinue) -ne $null
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.json5.from-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    node_available = $nodeAvailable
                    node_exit_code = $LASTEXITCODE
                }
            }
            else {
                Write-Error "Failed to convert JSON to JSON5: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.json5.from-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.json5.from-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # JSONL to JSON
    Set-Item -Path Function:Global:_ConvertFrom-JsonLToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.jsonl.to-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.jsonl$', '.json'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonl.to-json] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $lines = Get-Content -LiteralPath $InputPath
            $lineCount = $lines.Count
            $objects = @()
            foreach ($line in $lines) {
                if (-not [string]::IsNullOrWhiteSpace($line)) {
                    $objects += $line | ConvertFrom-Json
                }
            }
            $objects | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonl.to-json] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.jsonl.to-json] Lines processed: $lineCount, Objects created: $($objects.Count)"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.jsonl.to-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Lines: $lineCount, Objects: $($objects.Count)" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.jsonl.to-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert JSONL to JSON: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonl.to-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.jsonl.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # JSON to JSONL
    Set-Item -Path Function:Global:_ConvertTo-JsonLFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.jsonl.from-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.jsonl'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonl.from-json] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $data = Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json
            $output = @()
            $objectCount = 0
            if ($data -is [array]) {
                foreach ($item in $data) {
                    $output += ($item | ConvertTo-Json -Compress -Depth 100)
                    $objectCount++
                }
            }
            else {
                $output += ($data | ConvertTo-Json -Compress -Depth 100)
                $objectCount = 1
            }
            $output | Set-Content -LiteralPath $OutputPath -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonl.from-json] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.jsonl.from-json] Objects converted: $objectCount"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.jsonl.from-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Objects: $objectCount" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.jsonl.from-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert JSON to JSONL: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.jsonl.from-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.jsonl.from-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force
}

# Convert JSON5 to JSON
<#
.SYNOPSIS
    Converts JSON5 file to JSON format.
.DESCRIPTION
    Converts a JSON5 file (JSON with comments and trailing commas) to standard JSON format.
    Requires Node.js and the json5 package to be installed.
.PARAMETER InputPath
    The path to the JSON5 file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-Json5ToJson {
    param([string]$InputPath, [string]$OutputPath)
    
    # Parse debug level once at function start
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        # Debug is enabled
    }
    
    if (-not $global:FileConversionDataInitialized) {
        Ensure-FileConversion-Data
    }
    try {
        _ConvertFrom-Json5ToJson @PSBoundParameters
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
            $nodeAvailable = (Get-Command node -ErrorAction SilentlyContinue) -ne $null
            Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.json5.to-json' -Context @{
                input_path = $InputPath
                output_path = $OutputPath
                input_size_bytes = $inputSize
                error_type = $_.Exception.GetType().FullName
                node_available = $nodeAvailable
                node_exit_code = $LASTEXITCODE
            }
        }
        else {
            Write-Error "Failed to convert JSON5 to JSON: $($_.Exception.Message)"
        }
        
        # Level 2: Error details
        if ($debugLevel -ge 2) {
            Write-Verbose "[conversion.json5.to-json] Error type: $($_.Exception.GetType().FullName)"
        }
        
        # Level 3: Stack trace
        if ($debugLevel -ge 3) {
            Write-Host "  [conversion.json5.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        }
        
        throw
    }
}
Set-Alias -Name json5-to-json -Value ConvertFrom-Json5ToJson -ErrorAction SilentlyContinue

# Convert JSON to JSON5
<#
.SYNOPSIS
    Converts JSON file to JSON5 format.
.DESCRIPTION
    Converts a JSON file to JSON5 format (JSON with comments and trailing commas support).
    Requires Node.js and the json5 package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output JSON5 file. If not specified, uses input path with .json5 extension.
#>
function ConvertTo-Json5FromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) {
        Ensure-FileConversion-Data
    }
    _ConvertTo-Json5FromJson @PSBoundParameters
}
Set-Alias -Name json-to-json5 -Value ConvertTo-Json5FromJson -ErrorAction SilentlyContinue

# Convert JSONL to JSON
<#
.SYNOPSIS
    Converts JSONL file to JSON format.
.DESCRIPTION
    Converts a JSONL (JSON Lines) file to a JSON array format.
.PARAMETER InputPath
    The path to the JSONL file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-JsonLToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertFrom-JsonLToJson @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert JSONL to JSON: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name jsonl-to-json -Value ConvertFrom-JsonLToJson -ErrorAction SilentlyContinue

# Convert JSON to JSONL
<#
.SYNOPSIS
    Converts JSON file to JSONL format.
.DESCRIPTION
    Converts a JSON file (array or object) to JSONL (JSON Lines) format, with one JSON object per line.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output JSONL file. If not specified, uses input path with .jsonl extension.
#>
function ConvertTo-JsonLFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertTo-JsonLFromJson @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert JSON to JSONL: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name json-to-jsonl -Value ConvertTo-JsonLFromJson -ErrorAction SilentlyContinue

# Convert XML to YAML
<#
.SYNOPSIS
    Converts XML file to YAML format.
.DESCRIPTION
    Converts an XML file directly to YAML format using yq.
    This direct conversion is more efficient than converting through JSON.
    Requires yq to be installed.
.PARAMETER InputPath
    The path to the XML file.
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
#>
function ConvertFrom-XmlToYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertFrom-XmlToYaml @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert XML to YAML: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name xml-to-yaml -Value ConvertFrom-XmlToYaml -ErrorAction SilentlyContinue

# Convert YAML to XML
<#
.SYNOPSIS
    Converts YAML file to XML format.
.DESCRIPTION
    Converts a YAML file directly to XML format using yq.
    This direct conversion is more efficient than converting through JSON.
    Requires yq to be installed.
.PARAMETER InputPath
    The path to the YAML file.
.PARAMETER OutputPath
    The path for the output XML file. If not specified, uses input path with .xml extension.
#>
function ConvertFrom-YamlToXml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertFrom-YamlToXml @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert YAML to XML: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name yaml-to-xml -Value ConvertFrom-YamlToXml -ErrorAction SilentlyContinue