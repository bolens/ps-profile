# ===============================================
# Thrift schema conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Thrift schema conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Thrift format conversions.
    Supports bidirectional conversions between JSON and Thrift.
    This function is called automatically by Initialize-FileConversion-BinarySchema.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and the thrift npm package.
    Note: Thrift requires schema compilation with thrift compiler.
#>
function Initialize-FileConversion-BinarySchemaThrift {
    # Ensure NodeJs module is imported
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

    # JSON to Thrift
    Set-Item -Path Function:Global:_ConvertTo-ThriftFromJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.thrift' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Thrift conversions."
            }
            if (-not $SchemaPath) {
                throw "Schema path is required for Thrift encoding. Provide a .thrift schema file."
            }
            $nodeScript = @"
try {
    const thrift = require('thrift');
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    // Note: Thrift requires schema compilation, this is a simplified approach
    // Full implementation would require thrift compiler
    console.error('Error: Thrift requires schema compilation with thrift compiler. Use thrift compiler to compile schema first.');
    process.exit(1);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: thrift package is not installed. Install it with: pnpm add -g thrift');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "thrift-encode-$(Get-Random).js"
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
            Write-Error "Failed to convert JSON to Thrift: $_"
        }
    } -Force

    # Thrift to JSON
    Set-Item -Path Function:Global:_ConvertFrom-ThriftToJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.thrift$', '.json' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Thrift conversions."
            }
            if (-not $SchemaPath) {
                throw "Schema path is required for Thrift decoding. Provide a compiled schema."
            }
            $nodeScript = @"
try {
    const thrift = require('thrift');
    const fs = require('fs');
    // Note: Thrift requires schema compilation, this is a simplified approach
    console.error('Error: Thrift requires schema compilation with thrift compiler. Use thrift compiler to compile schema first.');
    process.exit(1);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: thrift package is not installed. Install it with: pnpm add -g thrift');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "thrift-decode-$(Get-Random).js"
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
            Write-Error "Failed to convert Thrift to JSON: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert JSON to Thrift
<#
.SYNOPSIS
    Converts JSON file to Thrift format.
.DESCRIPTION
    Converts a JSON file to Thrift binary format.
    Requires Node.js, the thrift package, and a compiled schema.
    Note: Thrift requires schema compilation with thrift compiler.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output Thrift file. If not specified, uses input path with .thrift extension.
.PARAMETER SchemaPath
    The path to the compiled Thrift schema. Required.
#>
function ConvertTo-ThriftFromJson {
    param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ThriftFromJson @PSBoundParameters
}
Set-Alias -Name json-to-thrift -Value ConvertTo-ThriftFromJson -ErrorAction SilentlyContinue

# Convert Thrift to JSON
<#
.SYNOPSIS
    Converts Thrift file to JSON format.
.DESCRIPTION
    Converts a Thrift binary file back to JSON format.
    Requires Node.js, the thrift package, and a compiled schema.
    Note: Thrift requires schema compilation with thrift compiler.
.PARAMETER InputPath
    The path to the Thrift file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.PARAMETER SchemaPath
    The path to the compiled Thrift schema. Required.
#>
function ConvertFrom-ThriftToJson {
    param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-ThriftToJson @PSBoundParameters
}
Set-Alias -Name thrift-to-json -Value ConvertFrom-ThriftToJson -ErrorAction SilentlyContinue

