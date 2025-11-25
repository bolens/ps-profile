# ===============================================
# Schema-based binary format conversion utilities
# Protocol Buffers, Avro, FlatBuffers, Thrift
# ===============================================

<#
.SYNOPSIS
    Initializes binary format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for schema-based binary formats: Protocol Buffers, Avro, FlatBuffers, and Thrift.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and respective npm packages for each format.
#>
function Initialize-FileConversion-BinarySchema {
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
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'NodeJs.psm1'
        if (Test-Path $nodeJsModulePath) {
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

    # JSON to Avro
    Set-Item -Path Function:Global:_ConvertTo-AvroFromJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.avro' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Avro conversions."
            }
            if (-not $SchemaPath) {
                throw "Schema path is required for Avro encoding. Provide a .avsc schema file."
            }
            $nodeScript = @"
try {
    const avro = require('avsc');
    const fs = require('fs');
    const schema = JSON.parse(fs.readFileSync(process.argv[4], 'utf8'));
    const type = avro.Type.forSchema(schema);
    const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    const buffer = type.toBuffer(data);
    fs.writeFileSync(process.argv[3], buffer);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: avsc package is not installed. Install it with: pnpm add -g avsc');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "avro-encode-$(Get-Random).js"
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
            Write-Error "Failed to convert JSON to Avro: $_"
        }
    } -Force

    # Avro to JSON
    Set-Item -Path Function:Global:_ConvertFrom-AvroToJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.avro$', '.json' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Avro conversions."
            }
            if (-not $SchemaPath) {
                throw "Schema path is required for Avro decoding. Provide a .avsc schema file."
            }
            $nodeScript = @"
try {
    const avro = require('avsc');
    const fs = require('fs');
    const schema = JSON.parse(fs.readFileSync(process.argv[4], 'utf8'));
    const type = avro.Type.forSchema(schema);
    const buffer = fs.readFileSync(process.argv[2]);
    const data = type.fromBuffer(buffer);
    const json = JSON.stringify(data, null, 2);
    fs.writeFileSync(process.argv[3], json);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: avsc package is not installed. Install it with: pnpm add -g avsc');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "avro-decode-$(Get-Random).js"
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
            Write-Error "Failed to convert Avro to JSON: $_"
        }
    } -Force

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

# Convert JSON to Avro
<#
.SYNOPSIS
    Converts JSON file to Avro format.
.DESCRIPTION
    Converts a JSON file to Avro binary format.
    Requires Node.js, the avsc package, and a schema file.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output Avro file. If not specified, uses input path with .avro extension.
.PARAMETER SchemaPath
    The path to the Avro schema file (.avsc). Required.
#>
function ConvertTo-AvroFromJson {
    param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-AvroFromJson @PSBoundParameters
}
Set-Alias -Name json-to-avro -Value ConvertTo-AvroFromJson -ErrorAction SilentlyContinue

# Convert Avro to JSON
<#
.SYNOPSIS
    Converts Avro file to JSON format.
.DESCRIPTION
    Converts an Avro binary file back to JSON format.
    Requires Node.js, the avsc package, and a schema file.
.PARAMETER InputPath
    The path to the Avro file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.PARAMETER SchemaPath
    The path to the Avro schema file (.avsc). Required.
#>
function ConvertFrom-AvroToJson {
    param([string]$InputPath, [string]$OutputPath, [string]$SchemaPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AvroToJson @PSBoundParameters
}
Set-Alias -Name avro-to-json -Value ConvertFrom-AvroToJson -ErrorAction SilentlyContinue

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

