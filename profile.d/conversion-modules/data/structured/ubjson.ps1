# ===============================================
# UBJSON (Universal Binary JSON) format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes UBJSON format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for UBJSON (Universal Binary JSON) format.
    UBJSON is a binary format that represents JSON data structures in a compact binary form.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    UBJSON is a binary encoding of JSON that is more compact and faster to parse.
    Reference: http://ubjson.org/
#>
function Initialize-FileConversion-Ubjson {
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
        if ($nodeJsModulePath -and -not [string]::IsNullOrWhiteSpace($nodeJsModulePath) -and (Test-Path -LiteralPath $nodeJsModulePath)) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
        }
    }

    # UBJSON to JSON
    Set-Item -Path Function:Global:_ConvertFrom-UbjsonToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(ubjson|ubj)$', '.json'
            }
            
            # Try Node.js with ubjson package
            if (Get-Command node -ErrorAction SilentlyContinue) {
                $nodeScript = @"
try {
    const fs = require('fs');
    const buffer = fs.readFileSync(process.argv[2]);
    
    // Try to use ubjson package
    try {
        const ubjson = require('ubjson');
        const data = ubjson.deserialize(buffer);
        const json = JSON.stringify(data, null, 2);
        fs.writeFileSync(process.argv[3], json);
    } catch (e) {
        if (e.code === 'MODULE_NOT_FOUND') {
            throw new Error('ubjson package is not installed. Install with: pnpm add -g ubjson');
        } else {
            throw e;
        }
    }
} catch (error) {
    if (error.message.includes('ubjson')) {
        console.error('Error: ubjson package is not installed. Install it with: pnpm add -g ubjson');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
                $tempScript = Join-Path $env:TEMP "ubjson-to-json-$(Get-Random).js"
                Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
                try {
                    $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $InputPath, $OutputPath
                    if ($LASTEXITCODE -ne 0) {
                        throw "Node.js script failed: $result"
                    }
                    return
                }
                finally {
                    Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
                }
            }
            
            throw "Node.js is not available. Install Node.js and ubjson package (pnpm add -g ubjson) to use UBJSON conversions."
        }
        catch {
            Write-Error "Failed to convert UBJSON to JSON: $_"
            throw
        }
    } -Force

    # JSON to UBJSON
    Set-Item -Path Function:Global:_ConvertTo-UbjsonFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.ubjson'
            }
            
            # Try Node.js with ubjson package
            if (Get-Command node -ErrorAction SilentlyContinue) {
                $nodeScript = @"
try {
    const fs = require('fs');
    const jsonContent = fs.readFileSync(process.argv[2], 'utf8');
    const data = JSON.parse(jsonContent);
    
    // Try to use ubjson package
    try {
        const ubjson = require('ubjson');
        const buffer = ubjson.serialize(data);
        fs.writeFileSync(process.argv[3], buffer);
    } catch (e) {
        if (e.code === 'MODULE_NOT_FOUND') {
            throw new Error('ubjson package is not installed. Install with: pnpm add -g ubjson');
        } else {
            throw e;
        }
    }
} catch (error) {
    if (error.message.includes('ubjson')) {
        console.error('Error: ubjson package is not installed. Install it with: pnpm add -g ubjson');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
                $tempScript = Join-Path $env:TEMP "json-to-ubjson-$(Get-Random).js"
                Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
                try {
                    $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $InputPath, $OutputPath
                    if ($LASTEXITCODE -ne 0) {
                        throw "Node.js script failed: $result"
                    }
                    return
                }
                finally {
                    Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
                }
            }
            
            throw "Node.js is not available. Install Node.js and ubjson package (pnpm add -g ubjson) to use UBJSON conversions."
        }
        catch {
            Write-Error "Failed to convert JSON to UBJSON: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert UBJSON to JSON
<#
.SYNOPSIS
    Converts UBJSON file to JSON format.
.DESCRIPTION
    Converts a UBJSON (Universal Binary JSON) file to JSON format.
    UBJSON is a binary encoding of JSON that is more compact and faster to parse.
    Requires Node.js and the ubjson package to be installed.
.PARAMETER InputPath
    The path to the UBJSON file (.ubjson or .ubj extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.EXAMPLE
    ConvertFrom-UbjsonToJson -InputPath 'data.ubjson'
    
    Converts data.ubjson to data.json.
.OUTPUTS
    System.String
    Returns the path to the output JSON file.
#>
Set-Item -Path Function:Global:ConvertFrom-UbjsonToJson -Value {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-UbjsonToJson @PSBoundParameters
} -Force
Set-Alias -Name ubjson-to-json -Value ConvertFrom-UbjsonToJson -ErrorAction SilentlyContinue

# Convert JSON to UBJSON
<#
.SYNOPSIS
    Converts JSON file to UBJSON format.
.DESCRIPTION
    Converts a JSON file to UBJSON (Universal Binary JSON) format.
    UBJSON is a binary encoding of JSON that is more compact and faster to parse.
    Requires Node.js and the ubjson package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output UBJSON file. If not specified, uses input path with .ubjson extension.
.EXAMPLE
    ConvertTo-UbjsonFromJson -InputPath 'data.json'
    
    Converts data.json to data.ubjson.
.OUTPUTS
    System.String
    Returns the path to the output UBJSON file.
#>
Set-Item -Path Function:Global:ConvertTo-UbjsonFromJson -Value {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-UbjsonFromJson @PSBoundParameters
} -Force
Set-Alias -Name json-to-ubjson -Value ConvertTo-UbjsonFromJson -ErrorAction SilentlyContinue

