# ===============================================
# CFG/ConfigParser format conversion utilities
# CFG ↔ JSON, YAML, INI
# ========================================

<#
.SYNOPSIS
    Initializes CFG/ConfigParser format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for CFG/ConfigParser format.
    CFG/ConfigParser is Python's configuration file format, similar to INI but with some differences.
    Supports bidirectional conversions between CFG and JSON, YAML, and INI formats.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    CFG/ConfigParser format supports sections, key-value pairs, and comments.
    Uses Python's configparser module for proper parsing.
#>
function Initialize-FileConversion-Cfg {
    # Ensure Python module is imported (use repo root from bootstrap if available)
    if (-not (Get-Command Get-PythonPath -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Variable -Name 'RepoRoot' -Scope Script -ErrorAction SilentlyContinue) {
            $script:RepoRoot
        }
        elseif (Get-Variable -Name 'BootstrapRoot' -Scope Script -ErrorAction SilentlyContinue) {
            Split-Path -Parent $script:BootstrapRoot
        }
        else {
            Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        }
        $pythonModulePath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'Python.psm1'
        if ($pythonModulePath -and -not [string]::IsNullOrWhiteSpace($pythonModulePath) -and (Test-Path -LiteralPath $pythonModulePath)) {
            Import-Module $pythonModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
        }
    }

    # CFG to JSON
    Set-Item -Path Function:Global:_ConvertFrom-CfgToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.cfg.to-json] Starting conversion: $InputPath"
            }
            
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(cfg|conf|config)$', '.json' }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.to-json] Output path: $OutputPath"
            }
            
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python to use CFG/ConfigParser conversions."
            }
            $pythonScript = @"
import json
import sys
try:
    import configparser
except ImportError:
    print('Error: configparser is part of Python standard library and should be available.', file=sys.stderr)
    sys.exit(1)

try:
    config = configparser.ConfigParser()
    config.read(sys.argv[1])
    
    result = {}
    for section in config.sections():
        result[section] = {}
        for key, value in config.items(section):
            result[section][key] = value
    
    # Handle DEFAULT section if present
    if config.defaults():
        result['DEFAULT'] = dict(config.defaults())
    
    with open(sys.argv[2], 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "cfg-to-json-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
            
            # Level 1: Conversion execution
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.cfg.to-json] Executing Python conversion script"
            }
            
            $convStartTime = Get-Date
            try {
                $result = & $pythonCmd $tempScript $InputPath $OutputPath 2>&1
                $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Python script failed: $result"
                }
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.cfg.to-json] Conversion completed in ${convDuration}ms"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    $inputSize = if (Test-Path $InputPath) { (Get-Item $InputPath).Length } else { 0 }
                    $outputSize = if (Test-Path $OutputPath) { (Get-Item $OutputPath).Length } else { 0 }
                    Write-Host "  [conversion.cfg.to-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.cfg.to-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                }
            }
            else {
                Write-Error "Failed to convert CFG to JSON: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.to-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.cfg.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # JSON to CFG
    Set-Item -Path Function:Global:_ConvertTo-CfgFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.cfg.from-json] Starting conversion: $InputPath"
            }
            
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.cfg' }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.from-json] Output path: $OutputPath"
            }
            
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python to use CFG/ConfigParser conversions."
            }
            $pythonScript = @"
import json
import sys
try:
    import configparser
except ImportError:
    print('Error: configparser is part of Python standard library and should be available.', file=sys.stderr)
    sys.exit(1)

try:
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    config = configparser.ConfigParser()
    
    # Handle DEFAULT section
    if 'DEFAULT' in data:
        for key, value in data['DEFAULT'].items():
            config['DEFAULT'][key] = str(value)
        del data['DEFAULT']
    
    # Add other sections
    for section, items in data.items():
        if isinstance(items, dict):
            config.add_section(section)
            for key, value in items.items():
                config.set(section, key, str(value))
    
    with open(sys.argv[2], 'w', encoding='utf-8') as f:
        config.write(f)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "json-to-cfg-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
            
            # Level 1: Conversion execution
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.cfg.from-json] Executing Python conversion script"
            }
            
            $convStartTime = Get-Date
            try {
                $result = & $pythonCmd $tempScript $InputPath $OutputPath 2>&1
                $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Python script failed: $result"
                }
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.cfg.from-json] Conversion completed in ${convDuration}ms"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                    $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                    Write-Host "  [conversion.cfg.from-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.cfg.from-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    python_exit_code = $LASTEXITCODE
                }
            }
            else {
                Write-Error "Failed to convert JSON to CFG: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.from-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.cfg.from-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # CFG to YAML
    Set-Item -Path Function:Global:_ConvertFrom-CfgToYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.cfg.to-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(cfg|conf|config)$', '.yaml' }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.to-yaml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert CFG to JSON first, then to YAML
            $tempJson = Join-Path $env:TEMP "cfg-to-yaml-$(Get-Random).json"
            try {
                _ConvertFrom-CfgToJson -InputPath $InputPath -OutputPath $tempJson
                
                # Convert JSON to YAML
                $jsonContent = Get-Content -LiteralPath $tempJson -Raw
                $jsonObj = $jsonContent | ConvertFrom-Json
                $yaml = $jsonObj | ConvertTo-Yaml -ErrorAction SilentlyContinue
                if (-not $yaml) {
                    # Fallback: simple key-value format
                    $yamlLines = @()
                    if ($jsonObj -is [PSCustomObject]) {
                        $jsonObj.PSObject.Properties | ForEach-Object {
                            if ($_.Value -is [PSCustomObject]) {
                                $yamlLines += "$($_.Name):"
                                $_.Value.PSObject.Properties | ForEach-Object {
                                    $yamlLines += "  $($_.Name): $($_.Value)"
                                }
                            }
                            else {
                                $yamlLines += "$($_.Name): $($_.Value)"
                            }
                        }
                    }
                    $yaml = $yamlLines -join "`r`n"
                }
                Set-Content -LiteralPath $OutputPath -Value $yaml -Encoding UTF8
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.to-yaml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.cfg.to-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.cfg.to-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert CFG to YAML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.to-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.cfg.to-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # YAML to CFG
    Set-Item -Path Function:Global:_ConvertTo-CfgFromYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.cfg.from-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.ya?ml$', '.cfg' }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.from-yaml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert YAML to JSON first, then to CFG
            $tempJson = Join-Path $env:TEMP "yaml-to-cfg-$(Get-Random).json"
            try {
                # Convert YAML to JSON
                $yamlContent = Get-Content -LiteralPath $InputPath -Raw
                $yamlObj = $yamlContent | ConvertFrom-Yaml -ErrorAction SilentlyContinue
                if (-not $yamlObj) {
                    # Fallback: simple parsing
                    $yamlObj = @{}
                    $lines = $yamlContent -split "`r?`n"
                    foreach ($line in $lines) {
                        if ($line -match '^([^:]+):\s*(.*)$') {
                            $yamlObj[$matches[1].Trim()] = $matches[2].Trim()
                        }
                    }
                }
                $json = $yamlObj | ConvertTo-Json -Depth 100
                Set-Content -LiteralPath $tempJson -Value $json -Encoding UTF8
                
                # Convert JSON to CFG
                _ConvertTo-CfgFromJson -InputPath $tempJson -OutputPath $OutputPath
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.from-yaml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.cfg.from-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.cfg.from-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert YAML to CFG: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.from-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.cfg.from-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # CFG to INI
    Set-Item -Path Function:Global:_ConvertFrom-CfgToIni -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.cfg.to-ini] Starting conversion: $InputPath"
            }
            
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(cfg|conf|config)$', '.ini' }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.to-ini] Output path: $OutputPath"
            }
            
            # CFG and INI are very similar formats, so we can mostly copy the content
            # But we'll use Python's configparser to ensure proper handling
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python to use CFG/ConfigParser conversions."
            }
            $pythonScript = @"
import sys
try:
    import configparser
except ImportError:
    print('Error: configparser is part of Python standard library and should be available.', file=sys.stderr)
    sys.exit(1)

try:
    config = configparser.ConfigParser()
    config.read(sys.argv[1])
    
    with open(sys.argv[2], 'w', encoding='utf-8') as f:
        config.write(f)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "cfg-to-ini-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
            
            # Level 1: Conversion execution
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.cfg.to-ini] Executing Python conversion script"
            }
            
            $convStartTime = Get-Date
            try {
                $result = & $pythonCmd $tempScript $InputPath $OutputPath 2>&1
                $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Python script failed: $result"
                }
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.cfg.to-ini] Conversion completed in ${convDuration}ms"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                    $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                    Write-Host "  [conversion.cfg.to-ini] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.cfg.to-ini' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    python_exit_code = $LASTEXITCODE
                }
            }
            else {
                Write-Error "Failed to convert CFG to INI: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.to-ini] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.cfg.to-ini] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # INI to CFG
    Set-Item -Path Function:Global:_ConvertTo-CfgFromIni -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.cfg.from-ini] Starting conversion: $InputPath"
            }
            
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.ini$', '.cfg' }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.from-ini] Output path: $OutputPath"
            }
            
            # INI and CFG are very similar formats, so we can mostly copy the content
            # But we'll use Python's configparser to ensure proper handling
            $pythonCmd = Get-PythonPath
            if (-not $pythonCmd) {
                throw "Python is not available. Install Python to use CFG/ConfigParser conversions."
            }
            $pythonScript = @"
import sys
try:
    import configparser
except ImportError:
    print('Error: configparser is part of Python standard library and should be available.', file=sys.stderr)
    sys.exit(1)

try:
    config = configparser.ConfigParser()
    config.read(sys.argv[1])
    
    with open(sys.argv[2], 'w', encoding='utf-8') as f:
        config.write(f)
except Exception as e:
    print(f'Error: {str(e)}', file=sys.stderr)
    sys.exit(1)
"@
            $tempScript = Join-Path $env:TEMP "ini-to-cfg-$(Get-Random).py"
            Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8
            
            # Level 1: Conversion execution
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.cfg.from-ini] Executing Python conversion script"
            }
            
            $convStartTime = Get-Date
            try {
                $result = & $pythonCmd $tempScript $InputPath $OutputPath 2>&1
                $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Python script failed: $result"
                }
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.cfg.from-ini] Conversion completed in ${convDuration}ms"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                    $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                    Write-Host "  [conversion.cfg.from-ini] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.cfg.from-ini' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    python_exit_code = $LASTEXITCODE
                }
            }
            else {
                Write-Error "Failed to convert INI to CFG: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.cfg.from-ini] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.cfg.from-ini] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert CFG to JSON
<#
.SYNOPSIS
    Converts CFG/ConfigParser file to JSON format.
.DESCRIPTION
    Converts a CFG/ConfigParser (Python configuration) file to JSON format.
    Requires Python with configparser module (part of standard library).
.PARAMETER InputPath
    The path to the CFG file (.cfg, .conf, or .config extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-CfgToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-CfgToJson @PSBoundParameters
}
Set-Alias -Name cfg-to-json -Value ConvertFrom-CfgToJson -ErrorAction SilentlyContinue
Set-Alias -Name configparser-to-json -Value ConvertFrom-CfgToJson -ErrorAction SilentlyContinue

# Convert JSON to CFG
<#
.SYNOPSIS
    Converts JSON file to CFG/ConfigParser format.
.DESCRIPTION
    Converts a JSON file to CFG/ConfigParser (Python configuration) format.
    Requires Python with configparser module (part of standard library).
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output CFG file. If not specified, uses input path with .cfg extension.
#>
function ConvertTo-CfgFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-CfgFromJson @PSBoundParameters
}
Set-Alias -Name json-to-cfg -Value ConvertTo-CfgFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-configparser -Value ConvertTo-CfgFromJson -ErrorAction SilentlyContinue

# Convert CFG to YAML
<#
.SYNOPSIS
    Converts CFG/ConfigParser file to YAML format.
.DESCRIPTION
    Converts a CFG/ConfigParser file to YAML format.
    Converts through JSON as an intermediate format.
.PARAMETER InputPath
    The path to the CFG file (.cfg, .conf, or .config extension).
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
#>
function ConvertFrom-CfgToYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-CfgToYaml @PSBoundParameters
}
Set-Alias -Name cfg-to-yaml -Value ConvertFrom-CfgToYaml -ErrorAction SilentlyContinue

# Convert YAML to CFG
<#
.SYNOPSIS
    Converts YAML file to CFG/ConfigParser format.
.DESCRIPTION
    Converts a YAML file to CFG/ConfigParser format.
    Converts through JSON as an intermediate format.
.PARAMETER InputPath
    The path to the YAML file.
.PARAMETER OutputPath
    The path for the output CFG file. If not specified, uses input path with .cfg extension.
#>
function ConvertTo-CfgFromYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-CfgFromYaml @PSBoundParameters
}
Set-Alias -Name yaml-to-cfg -Value ConvertTo-CfgFromYaml -ErrorAction SilentlyContinue

# Convert CFG to INI
<#
.SYNOPSIS
    Converts CFG/ConfigParser file to INI format.
.DESCRIPTION
    Converts a CFG/ConfigParser file to INI format.
    CFG and INI formats are very similar, so this is mostly a format conversion.
    Requires Python with configparser module (part of standard library).
.PARAMETER InputPath
    The path to the CFG file (.cfg, .conf, or .config extension).
.PARAMETER OutputPath
    The path for the output INI file. If not specified, uses input path with .ini extension.
#>
function ConvertFrom-CfgToIni {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-CfgToIni @PSBoundParameters
}
Set-Alias -Name cfg-to-ini -Value ConvertFrom-CfgToIni -ErrorAction SilentlyContinue

# Convert INI to CFG
<#
.SYNOPSIS
    Converts INI file to CFG/ConfigParser format.
.DESCRIPTION
    Converts an INI file to CFG/ConfigParser format.
    CFG and INI formats are very similar, so this is mostly a format conversion.
    Requires Python with configparser module (part of standard library).
.PARAMETER InputPath
    The path to the INI file.
.PARAMETER OutputPath
    The path for the output CFG file. If not specified, uses input path with .cfg extension.
#>
function ConvertTo-CfgFromIni {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-CfgFromIni @PSBoundParameters
}
Set-Alias -Name ini-to-cfg -Value ConvertTo-CfgFromIni -ErrorAction SilentlyContinue

