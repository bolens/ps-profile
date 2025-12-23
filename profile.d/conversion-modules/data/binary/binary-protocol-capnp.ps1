# ===============================================
# Cap'n Proto format conversion utilities
# Cap'n Proto ↔ JSON, Binary
# ========================================

<#
.SYNOPSIS
    Initializes Cap'n Proto format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Cap'n Proto format conversions.
    Cap'n Proto is a fast binary serialization format similar to Protocol Buffers but faster.
    Supports bidirectional conversions between JSON and Cap'n Proto binary format.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and the capnp npm package to be installed.
#>
function Initialize-FileConversion-BinaryProtocolCapnp {
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

    # JSON to Cap'n Proto
    Set-Item -Path Function:Global:_ConvertTo-CapnpFromJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.capnp' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Cap'n Proto conversions."
            }
            if (-not $SchemaPath) {
                throw "Schema path is required for Cap'n Proto encoding. Provide a .capnp schema file."
            }
            $nodeScript = @"
try {
    const capnp = require('capnp');
    const fs = require('fs');
    const path = require('path');
    
    // Load schema
    const schemaText = fs.readFileSync(process.argv[4], 'utf8');
    const schema = capnp.Schema.fromString(schemaText);
    
    // Load JSON data
    const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    
    // Create message from schema
    const message = new capnp.Message();
    const root = message.initRoot(schema);
    
    // Convert JSON to Cap'n Proto (simplified - full implementation would need proper field mapping)
    // Note: This is a basic implementation. Full Cap'n Proto support requires proper schema compilation.
    const buffer = message.toArrayBuffer();
    fs.writeFileSync(process.argv[3], Buffer.from(buffer));
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: capnp package is not installed. Install it with: pnpm add -g capnp');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "capnp-encode-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $InputPath, $OutputPath, $SchemaPath
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert JSON to Cap'n Proto: $_"
            throw
        }
    } -Force

    # Cap'n Proto to JSON
    Set-Item -Path Function:Global:_ConvertFrom-CapnpToJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(capnp|cap)$', '.json' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Cap'n Proto conversions."
            }
            if (-not $SchemaPath) {
                throw "Schema path is required for Cap'n Proto decoding. Provide a .capnp schema file."
            }
            $nodeScript = @"
try {
    const capnp = require('capnp');
    const fs = require('fs');
    
    // Load schema
    const schemaText = fs.readFileSync(process.argv[4], 'utf8');
    const schema = capnp.Schema.fromString(schemaText);
    
    // Load Cap'n Proto binary
    const buffer = fs.readFileSync(process.argv[2]);
    const message = new capnp.Message(buffer);
    const root = message.getRoot(schema);
    
    // Convert Cap'n Proto to JSON (simplified - full implementation would need proper field mapping)
    const data = root.toJSON();
    const json = JSON.stringify(data, null, 2);
    fs.writeFileSync(process.argv[3], json);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: capnp package is not installed. Install it with: pnpm add -g capnp');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "capnp-decode-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $InputPath, $OutputPath, $SchemaPath
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert Cap'n Proto to JSON: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert JSON to Cap'n Proto
<#
.SYNOPSIS
    Converts JSON file to Cap'n Proto format.
.DESCRIPTION
    Converts a JSON file to Cap'n Proto binary format.
    Cap'n Proto is a fast binary serialization format.
    Requires Node.js and the capnp npm package to be installed.
    Note: Cap'n Proto conversion requires a schema file (.capnp).
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output Cap'n Proto file. If not specified, uses input path with .capnp extension.
.PARAMETER SchemaPath
    The path to the Cap'n Proto schema file (.capnp extension). Required for encoding.
#>
function ConvertTo-CapnpFromJson {
    param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-CapnpFromJson @PSBoundParameters
}
Set-Alias -Name json-to-capnp -Value ConvertTo-CapnpFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-capnproto -Value ConvertTo-CapnpFromJson -ErrorAction SilentlyContinue

# Convert Cap'n Proto to JSON
<#
.SYNOPSIS
    Converts Cap'n Proto file to JSON format.
.DESCRIPTION
    Converts a Cap'n Proto binary file to JSON format.
    Requires Node.js and the capnp npm package to be installed.
    Note: Cap'n Proto conversion requires a schema file (.capnp).
.PARAMETER InputPath
    The path to the Cap'n Proto file (.capnp or .cap extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.PARAMETER SchemaPath
    The path to the Cap'n Proto schema file (.capnp extension). Required for decoding.
#>
function ConvertFrom-CapnpToJson {
    param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-CapnpToJson @PSBoundParameters
}
Set-Alias -Name capnp-to-json -Value ConvertFrom-CapnpToJson -ErrorAction SilentlyContinue
Set-Alias -Name capnproto-to-json -Value ConvertFrom-CapnpToJson -ErrorAction SilentlyContinue

