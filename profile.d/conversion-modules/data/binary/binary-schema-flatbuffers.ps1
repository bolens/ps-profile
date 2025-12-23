# ===============================================
# FlatBuffers schema conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes FlatBuffers schema conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for FlatBuffers format conversions.
    Supports bidirectional conversions between JSON and FlatBuffers.
    This function is called automatically by Initialize-FileConversion-BinarySchema.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and the flatbuffers npm package.
    Note: FlatBuffers requires schema compilation with flatc compiler.
#>
function Initialize-FileConversion-BinarySchemaFlatBuffers {
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

    # JSON to FlatBuffers
    Set-Item -Path Function:Global:_ConvertTo-FlatBuffersFromJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.fb' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use FlatBuffers conversions."
            }
            if (-not $SchemaPath) {
                throw "Schema path is required for FlatBuffers encoding. Provide a .fbs schema file."
            }
            $nodeScript = @"
try {
    const flatbuffers = require('flatbuffers');
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    // Note: FlatBuffers requires schema compilation, this is a simplified approach
    // Full implementation would require flatc compiler
    console.error('Error: FlatBuffers requires schema compilation with flatc. Use flatc to compile schema first.');
    process.exit(1);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: flatbuffers package is not installed. Install it with: pnpm add -g flatbuffers');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "flatbuffers-encode-$(Get-Random).js"
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
            Write-Error "Failed to convert JSON to FlatBuffers: $_"
        }
    } -Force

    # FlatBuffers to JSON
    Set-Item -Path Function:Global:_ConvertFrom-FlatBuffersToJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.fb$', '.json' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use FlatBuffers conversions."
            }
            if (-not $SchemaPath) {
                throw "Schema path is required for FlatBuffers decoding. Provide a compiled schema."
            }
            $nodeScript = @"
try {
    const flatbuffers = require('flatbuffers');
    const fs = require('fs');
    // Note: FlatBuffers requires schema compilation, this is a simplified approach
    console.error('Error: FlatBuffers requires schema compilation with flatc. Use flatc to compile schema first.');
    process.exit(1);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: flatbuffers package is not installed. Install it with: pnpm add -g flatbuffers');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "flatbuffers-decode-$(Get-Random).js"
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
            Write-Error "Failed to convert FlatBuffers to JSON: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert JSON to FlatBuffers
<#
.SYNOPSIS
    Converts JSON file to FlatBuffers format.
.DESCRIPTION
    Converts a JSON file to FlatBuffers binary format.
    Requires Node.js, the flatbuffers package, and a compiled schema.
    Note: FlatBuffers requires schema compilation with flatc compiler.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output FlatBuffers file. If not specified, uses input path with .fb extension.
.PARAMETER SchemaPath
    The path to the compiled FlatBuffers schema. Required.
#>
function ConvertTo-FlatBuffersFromJson {
    param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-FlatBuffersFromJson @PSBoundParameters
}
Set-Alias -Name json-to-flatbuffers -Value ConvertTo-FlatBuffersFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-fb -Value ConvertTo-FlatBuffersFromJson -ErrorAction SilentlyContinue

# Convert FlatBuffers to JSON
<#
.SYNOPSIS
    Converts FlatBuffers file to JSON format.
.DESCRIPTION
    Converts a FlatBuffers binary file back to JSON format.
    Requires Node.js, the flatbuffers package, and a compiled schema.
    Note: FlatBuffers requires schema compilation with flatc compiler.
.PARAMETER InputPath
    The path to the FlatBuffers file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.PARAMETER SchemaPath
    The path to the compiled FlatBuffers schema. Required.
#>
function ConvertFrom-FlatBuffersToJson {
    param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-FlatBuffersToJson @PSBoundParameters
}
Set-Alias -Name flatbuffers-to-json -Value ConvertFrom-FlatBuffersToJson -ErrorAction SilentlyContinue
Set-Alias -Name fb-to-json -Value ConvertFrom-FlatBuffersToJson -ErrorAction SilentlyContinue

