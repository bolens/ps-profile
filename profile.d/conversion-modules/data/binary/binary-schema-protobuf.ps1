# ===============================================
# Protocol Buffers (protobuf) schema conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Protocol Buffers schema conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Protocol Buffers (protobuf) format conversions.
    Supports bidirectional conversions between JSON and Protocol Buffers.
    This function is called automatically by Initialize-FileConversion-BinarySchema.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and the protobufjs npm package.
#>
function Initialize-FileConversion-BinarySchemaProtobuf {
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

    # JSON to Protocol Buffers (protobuf) - Note: Requires schema file
    Set-Item -Path Function:Global:_ConvertTo-ProtobufFromJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.pb' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Protocol Buffers conversions."
            }
            if (-not $SchemaPath) {
                throw "Schema path is required for Protocol Buffers encoding. Provide a .proto file or JSON schema."
            }
            $nodeScript = @"
try {
    const protobuf = require('protobufjs');
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    let root;
    if (process.argv[4].endsWith('.proto')) {
        root = protobuf.loadSync(process.argv[4]);
    } else {
        const schema = JSON.parse(fs.readFileSync(process.argv[4], 'utf8'));
        root = protobuf.Root.fromJSON(schema);
    }
    const messageType = root.lookupType(root.nestedArray[0]?.name || 'Message');
    const message = messageType.create(data);
    const buffer = messageType.encode(message).finish();
    fs.writeFileSync(process.argv[3], buffer);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: protobufjs package is not installed. Install it with: pnpm add -g protobufjs');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "protobuf-encode-$(Get-Random).js"
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
            Write-Error "Failed to convert JSON to Protocol Buffers: $_"
        }
    } -Force

    # Protocol Buffers (protobuf) to JSON - Note: Requires schema file
    Set-Item -Path Function:Global:_ConvertFrom-ProtobufToJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.pb$', '.json' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Protocol Buffers conversions."
            }
            if (-not $SchemaPath) {
                throw "Schema path is required for Protocol Buffers decoding. Provide a .proto file or JSON schema."
            }
            $nodeScript = @"
try {
    const protobuf = require('protobufjs');
    const fs = require('fs');
    let root;
    if (process.argv[4].endsWith('.proto')) {
        root = protobuf.loadSync(process.argv[4]);
    } else {
        const schema = JSON.parse(fs.readFileSync(process.argv[4], 'utf8'));
        root = protobuf.Root.fromJSON(schema);
    }
    const messageType = root.lookupType(root.nestedArray[0]?.name || 'Message');
    const buffer = fs.readFileSync(process.argv[2]);
    const message = messageType.decode(buffer);
    const json = JSON.stringify(messageType.toObject(message, { longs: String, enums: String, bytes: String, defaults: true, arrays: true, objects: true }), null, 2);
    fs.writeFileSync(process.argv[3], json);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: protobufjs package is not installed. Install it with: pnpm add -g protobufjs');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "protobuf-decode-$(Get-Random).js"
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
            Write-Error "Failed to convert Protocol Buffers to JSON: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert JSON to Protocol Buffers
<#
.SYNOPSIS
    Converts JSON file to Protocol Buffers format.
.DESCRIPTION
    Converts a JSON file to Protocol Buffers (protobuf) binary format.
    Requires Node.js, the protobufjs package, and a schema file.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output Protocol Buffers file. If not specified, uses input path with .pb extension.
.PARAMETER SchemaPath
    The path to the Protocol Buffers schema file (.proto or JSON schema). Required.
#>
function ConvertTo-ProtobufFromJson {
    param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ProtobufFromJson @PSBoundParameters
}
Set-Alias -Name json-to-protobuf -Value ConvertTo-ProtobufFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-pb -Value ConvertTo-ProtobufFromJson -ErrorAction SilentlyContinue

# Convert Protocol Buffers to JSON
<#
.SYNOPSIS
    Converts Protocol Buffers file to JSON format.
.DESCRIPTION
    Converts a Protocol Buffers (protobuf) binary file back to JSON format.
    Requires Node.js, the protobufjs package, and a schema file.
.PARAMETER InputPath
    The path to the Protocol Buffers file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.PARAMETER SchemaPath
    The path to the Protocol Buffers schema file (.proto or JSON schema). Required.
#>
function ConvertFrom-ProtobufToJson {
    param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-ProtobufToJson @PSBoundParameters
}
Set-Alias -Name protobuf-to-json -Value ConvertFrom-ProtobufToJson -ErrorAction SilentlyContinue
Set-Alias -Name pb-to-json -Value ConvertFrom-ProtobufToJson -ErrorAction SilentlyContinue

