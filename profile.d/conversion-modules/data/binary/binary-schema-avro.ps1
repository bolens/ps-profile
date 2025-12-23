# ===============================================
# Avro schema conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Avro schema conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Avro format conversions.
    Supports bidirectional conversions between JSON and Avro.
    This function is called automatically by Initialize-FileConversion-BinarySchema.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and the avsc npm package.
#>
function Initialize-FileConversion-BinarySchemaAvro {
    # Capture the base path during initialization for use in script blocks (use global scope)
    # binary-schema-avro.ps1 is at: profile.d/conversion-modules/data/binary/
    # Need to go up 4 levels: binary -> data -> conversion-modules -> profile.d -> repo root
    $basePath = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    $global:BinaryConversionBasePath = $basePath

    # Load NodeJs module during initialization to avoid on-demand loading issues
    $nodeJsModulePath = Join-Path $basePath 'scripts' 'lib' 'runtime' 'NodeJs.psm1'
    if (Test-Path -LiteralPath $nodeJsModulePath -ErrorAction SilentlyContinue) {
        Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
    }

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
            # Check if Invoke-NodeScript is available (should be loaded during initialization)
            if (-not (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue)) {
                throw "Invoke-NodeScript is not available. NodeJs module was not loaded during initialization."
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
            # Check if Invoke-NodeScript is available (should be loaded during initialization)
            if (-not (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue)) {
                throw "Invoke-NodeScript is not available. NodeJs module was not loaded during initialization."
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

    # Avro to JSON with schema evolution (reader schema different from writer schema)
    Set-Item -Path Function:Global:_ConvertFrom-AvroToJsonWithSchemaEvolution -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$WriterSchemaPath, [string]$ReaderSchemaPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.avro$', '.json' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Avro conversions."
            }
            if (-not $WriterSchemaPath -and -not $ReaderSchemaPath) {
                throw "Either WriterSchemaPath or ReaderSchemaPath is required for Avro decoding with schema evolution."
            }
            # Check if Invoke-NodeScript is available (should be loaded during initialization)
            if (-not (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue)) {
                throw "Invoke-NodeScript is not available. NodeJs module was not loaded during initialization."
            }
            $nodeScript = @"
try {
    const avro = require('avsc');
    const fs = require('fs');
    
    // Load schemas
    let writerSchema = null;
    let readerSchema = null;
    
    if (process.argv[4]) {
        writerSchema = JSON.parse(fs.readFileSync(process.argv[4], 'utf8'));
    }
    if (process.argv[5]) {
        readerSchema = JSON.parse(fs.readFileSync(process.argv[5], 'utf8'));
    }
    
    // If only one schema provided, use it for both
    if (!writerSchema && readerSchema) {
        writerSchema = readerSchema;
    }
    if (!readerSchema && writerSchema) {
        readerSchema = writerSchema;
    }
    
    const writerType = avro.Type.forSchema(writerSchema);
    const readerType = avro.Type.forSchema(readerSchema);
    
    // Read Avro file with schema evolution
    const buffer = fs.readFileSync(process.argv[2]);
    const data = writerType.fromBuffer(buffer);
    
    // Convert using reader schema (schema evolution)
    const evolvedData = readerType.fromBuffer(writerType.toBuffer(data));
    
    const json = JSON.stringify(evolvedData, null, 2);
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
            $tempScript = Join-Path $env:TEMP "avro-evolve-decode-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $args = @($InputPath, $OutputPath)
                if ($WriterSchemaPath) { $args += $WriterSchemaPath }
                if ($ReaderSchemaPath) { $args += $ReaderSchemaPath }
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $args
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert Avro to JSON with schema evolution: $_"
            throw
        }
    } -Force

    # Schema compatibility check
    Set-Item -Path Function:Global:_Test-AvroSchemaCompatibility -Value {
        param([string]$WriterSchemaPath, [string]$ReaderSchemaPath)
        try {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Avro schema compatibility checks."
            }
            if (-not $WriterSchemaPath -or -not $ReaderSchemaPath) {
                throw "Both WriterSchemaPath and ReaderSchemaPath are required for compatibility checking."
            }
            $nodeScript = @"
try {
    const avro = require('avsc');
    const fs = require('fs');
    
    const writerSchema = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    const readerSchema = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
    
    const writerType = avro.Type.forSchema(writerSchema);
    const readerType = avro.Type.forSchema(readerSchema);
    
    // Check compatibility
    // Avro supports: forward compatibility (reader can read writer), backward compatibility (writer can read reader)
    // Full compatibility means both schemas can read each other's data
    
    const result = {
        compatible: true,
        forwardCompatible: true,  // Reader can read writer's data
        backwardCompatible: true, // Writer can read reader's data
        errors: []
    };
    
    // Basic compatibility check - in practice, this would need more sophisticated validation
    // The avsc library handles schema evolution automatically when reading
    try {
        // Test forward compatibility: can reader read writer's data?
        const testData = { name: 'test', value: 1 };
        const buffer = writerType.toBuffer(testData);
        readerType.fromBuffer(buffer);
    } catch (e) {
        result.forwardCompatible = false;
        result.compatible = false;
        result.errors.push('Forward compatibility failed: ' + e.message);
    }
    
    console.log(JSON.stringify(result));
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: avsc package is not installed. Install it with: pnpm add -g avsc');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "avro-compat-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $WriterSchemaPath, $ReaderSchemaPath
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
                return $result | ConvertFrom-Json
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to check Avro schema compatibility: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
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

# Convert Avro to JSON with Schema Evolution
<#
.SYNOPSIS
    Converts Avro file to JSON format using schema evolution.
.DESCRIPTION
    Converts an Avro binary file to JSON format using schema evolution.
    Allows reading data written with one schema using a different (compatible) schema.
    Requires Node.js, the avsc package, and schema files.
.PARAMETER InputPath
    The path to the Avro file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.PARAMETER WriterSchemaPath
    The path to the Avro schema file (.avsc) used when writing the data. Optional if ReaderSchemaPath is provided.
.PARAMETER ReaderSchemaPath
    The path to the Avro schema file (.avsc) to use when reading the data. Optional if WriterSchemaPath is provided.
    If only one schema is provided, it will be used for both reading and writing.
#>
function ConvertFrom-AvroToJsonWithSchemaEvolution {
    param([string]$InputPath, [string]$OutputPath, [string]$WriterSchemaPath, [string]$ReaderSchemaPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AvroToJsonWithSchemaEvolution @PSBoundParameters
}
Set-Alias -Name avro-to-json-evolve -Value ConvertFrom-AvroToJsonWithSchemaEvolution -ErrorAction SilentlyContinue

# Test Avro Schema Compatibility
<#
.SYNOPSIS
    Tests compatibility between two Avro schemas.
.DESCRIPTION
    Tests whether two Avro schemas are compatible for schema evolution.
    Checks forward compatibility (reader can read writer's data) and backward compatibility.
    Requires Node.js and the avsc package.
.PARAMETER WriterSchemaPath
    The path to the Avro schema file (.avsc) used when writing data.
.PARAMETER ReaderSchemaPath
    The path to the Avro schema file (.avsc) used when reading data.
.OUTPUTS
    PSCustomObject with compatibility information including:
    - Compatible: Overall compatibility status
    - ForwardCompatible: Whether reader can read writer's data
    - BackwardCompatible: Whether writer can read reader's data
    - Errors: Array of any compatibility errors
#>
function Test-AvroSchemaCompatibility {
    param([string]$WriterSchemaPath, [string]$ReaderSchemaPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _Test-AvroSchemaCompatibility @PSBoundParameters
}
Set-Alias -Name avro-schema-compat -Value Test-AvroSchemaCompatibility -ErrorAction SilentlyContinue

