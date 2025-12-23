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
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json5$', '.json'
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
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $InputPath, $OutputPath
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert JSON5 to JSON: $_"
        }
    } -Force

    # JSON to JSON5
    Set-Item -Path Function:Global:_ConvertTo-Json5FromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.json5'
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
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $InputPath, $OutputPath
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert JSON to JSON5: $_"
        }
    } -Force

    # JSONL to JSON
    Set-Item -Path Function:Global:_ConvertFrom-JsonLToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.jsonl$', '.json'
            }
            $lines = Get-Content -LiteralPath $InputPath
            $objects = @()
            foreach ($line in $lines) {
                if (-not [string]::IsNullOrWhiteSpace($line)) {
                    $objects += $line | ConvertFrom-Json
                }
            }
            $objects | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JSONL to JSON: $_"
        }
    } -Force

    # JSON to JSONL
    Set-Item -Path Function:Global:_ConvertTo-JsonLFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.jsonl'
            }
            $data = Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json
            $output = @()
            if ($data -is [array]) {
                foreach ($item in $data) {
                    $output += ($item | ConvertTo-Json -Compress -Depth 100)
                }
            }
            else {
                $output += ($data | ConvertTo-Json -Compress -Depth 100)
            }
            $output | Set-Content -LiteralPath $OutputPath -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JSON to JSONL: $_"
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
    if (-not $global:FileConversionDataInitialized) {
        Ensure-FileConversion-Data
    }
    try {
        _ConvertFrom-Json5ToJson @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert JSON5 to JSON: $($_.Exception.Message)"
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