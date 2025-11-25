# ===============================================
# Simple binary format conversion utilities
# BSON, MessagePack, CBOR
# ===============================================

<#
.SYNOPSIS
    Initializes binary format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for simple binary formats: BSON, MessagePack, and CBOR.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and respective npm packages for each format.
#>
function Initialize-FileConversion-BinarySimple {
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
    # JSON to BSON
    Set-Item -Path Function:Global:_ConvertTo-BsonFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.bson' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use BSON conversions."
            }
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $nodeScript = @"
try {
    const BSON = require('bson');
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    // BSON.serialize doesn't support arrays as root, so wrap arrays in an object
    const dataToSerialize = Array.isArray(data) ? { _data: data } : data;
    const bson = BSON.serialize(dataToSerialize);
    fs.writeFileSync(process.argv[3], bson);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: bson package is not installed. Install it with: pnpm add -g bson');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "bson-encode-$(Get-Random).js"
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
            Write-Error "Failed to convert JSON to BSON: $_"
        }
    } -Force

    # BSON to JSON
    Set-Item -Path Function:Global:_ConvertFrom-BsonToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.bson$', '.json' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use BSON conversions."
            }
            $nodeScript = @"
try {
    const BSON = require('bson');
    const fs = require('fs');
    const buffer = fs.readFileSync(process.argv[2]);
    let data = BSON.deserialize(buffer);
    // Unwrap arrays that were wrapped during serialization
    if (data && typeof data === 'object' && !Array.isArray(data) && data._data && Array.isArray(data._data) && Object.keys(data).length === 1) {
        data = data._data;
    }
    const json = JSON.stringify(data, null, 2);
    fs.writeFileSync(process.argv[3], json);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: bson package is not installed. Install it with: pnpm add -g bson');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "bson-decode-$(Get-Random).js"
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
            Write-Error "Failed to convert BSON to JSON: $_"
        }
    } -Force
    # JSON to MessagePack
    Set-Item -Path Function:Global:_ConvertTo-MessagePackFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.msgpack' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use MessagePack conversions."
            }
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $nodeScript = @"
try {
    const msgpack = require('@msgpack/msgpack');
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    const packed = msgpack.encode(data);
    fs.writeFileSync(process.argv[3], packed);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: @msgpack/msgpack package is not installed. Install it with: pnpm add -g @msgpack/msgpack');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "msgpack-encode-$(Get-Random).js"
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
            Write-Error "Failed to convert JSON to MessagePack: $_"
        }
    } -Force

    # MessagePack to JSON
    Set-Item -Path Function:Global:_ConvertFrom-MessagePackToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.msgpack$', '.json' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use MessagePack conversions."
            }
            $nodeScript = @"
try {
    const msgpack = require('@msgpack/msgpack');
    const fs = require('fs');
    const buffer = fs.readFileSync(process.argv[2]);
    const data = msgpack.decode(buffer);
    const json = JSON.stringify(data, null, 2);
    fs.writeFileSync(process.argv[3], json);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: @msgpack/msgpack package is not installed. Install it with: pnpm add -g @msgpack/msgpack');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "msgpack-decode-$(Get-Random).js"
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
            Write-Error "Failed to convert MessagePack to JSON: $_"
        }
    } -Force
    # JSON to CBOR
    Set-Item -Path Function:Global:_ConvertTo-CborFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.cbor' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use CBOR conversions."
            }
            $nodeScript = @"
try {
    const cbor = require('cbor');
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    const cborBuffer = cbor.encode(data);
    fs.writeFileSync(process.argv[3], cborBuffer);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: cbor package is not installed. Install it with: pnpm add -g cbor');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "cbor-encode-$(Get-Random).js"
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
            Write-Error "Failed to convert JSON to CBOR: $_"
        }
    } -Force

    # CBOR to JSON
    Set-Item -Path Function:Global:_ConvertFrom-CborToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.cbor$', '.json' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use CBOR conversions."
            }
            $nodeScript = @"
try {
    const cbor = require('cbor');
    const fs = require('fs');
    const buffer = fs.readFileSync(process.argv[2]);
    const data = cbor.decode(buffer);
    const json = JSON.stringify(data, null, 2);
    fs.writeFileSync(process.argv[3], json);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: cbor package is not installed. Install it with: pnpm add -g cbor');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "cbor-decode-$(Get-Random).js"
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
            Write-Error "Failed to convert CBOR to JSON: $_"
        }
    } -Force
}

# Convert JSON to BSON
<#
.SYNOPSIS
    Converts JSON file to BSON format.
.DESCRIPTION
    Converts a JSON file to BSON (Binary JSON) format.
    Requires Node.js and the bson package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output BSON file. If not specified, uses input path with .bson extension.
#>
function ConvertTo-BsonFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-BsonFromJson @PSBoundParameters
}
Set-Alias -Name json-to-bson -Value ConvertTo-BsonFromJson -ErrorAction SilentlyContinue

# Convert BSON to JSON
<#
.SYNOPSIS
    Converts BSON file to JSON format.
.DESCRIPTION
    Converts a BSON (Binary JSON) file back to JSON format.
    Requires Node.js and the bson package to be installed.
.PARAMETER InputPath
    The path to the BSON file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-BsonToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-BsonToJson @PSBoundParameters
}
Set-Alias -Name bson-to-json -Value ConvertFrom-BsonToJson -ErrorAction SilentlyContinue
# Convert JSON to MessagePack
<#
.SYNOPSIS
    Converts JSON file to MessagePack format.
.DESCRIPTION
    Converts a JSON file to MessagePack binary format.
    Requires Node.js and the @msgpack/msgpack package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output MessagePack file. If not specified, uses input path with .msgpack extension.
#>
function ConvertTo-MessagePackFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-MessagePackFromJson @PSBoundParameters
}
Set-Alias -Name json-to-msgpack -Value ConvertTo-MessagePackFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-messagepack -Value ConvertTo-MessagePackFromJson -ErrorAction SilentlyContinue

# Convert MessagePack to JSON
<#
.SYNOPSIS
    Converts MessagePack file to JSON format.
.DESCRIPTION
    Converts a MessagePack binary file back to JSON format.
    Requires Node.js and the @msgpack/msgpack package to be installed.
.PARAMETER InputPath
    The path to the MessagePack file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-MessagePackToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-MessagePackToJson @PSBoundParameters
}
Set-Alias -Name msgpack-to-json -Value ConvertFrom-MessagePackToJson -ErrorAction SilentlyContinue
Set-Alias -Name messagepack-to-json -Value ConvertFrom-MessagePackToJson -ErrorAction SilentlyContinue
# Convert JSON to CBOR
<#
.SYNOPSIS
    Converts JSON file to CBOR format.
.DESCRIPTION
    Converts a JSON file to CBOR (Concise Binary Object Representation) format.
    Requires Node.js and the cbor package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output CBOR file. If not specified, uses input path with .cbor extension.
#>
function ConvertTo-CborFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-CborFromJson @PSBoundParameters
}
Set-Alias -Name json-to-cbor -Value ConvertTo-CborFromJson -ErrorAction SilentlyContinue

# Convert CBOR to JSON
<#
.SYNOPSIS
    Converts CBOR file to JSON format.
.DESCRIPTION
    Converts a CBOR (Concise Binary Object Representation) file back to JSON format.
    Requires Node.js and the cbor package to be installed.
.PARAMETER InputPath
    The path to the CBOR file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-CborToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-CborToJson @PSBoundParameters
}
Set-Alias -Name cbor-to-json -Value ConvertFrom-CborToJson -ErrorAction SilentlyContinue
