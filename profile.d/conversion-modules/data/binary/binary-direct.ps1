# ===============================================
# Binary-to-binary direct conversion utilities
# Direct conversions between BSON, MessagePack, CBOR
# ===============================================

<#
.SYNOPSIS
    Initializes binary format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for binary-to-binary direct conversions between BSON, MessagePack, and CBOR.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and respective npm packages for each format.
#>
function Initialize-FileConversion-BinaryDirect {
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
}
# Convert BSON to MessagePack
<#
.SYNOPSIS
    Converts BSON file to MessagePack format.
.DESCRIPTION
    Converts a BSON (Binary JSON) file directly to MessagePack format without going through JSON.
    This direct conversion is more efficient than converting through JSON.
    Requires Node.js, the bson package, and the @msgpack/msgpack package to be installed.
.PARAMETER InputPath
    The path to the BSON file.
.PARAMETER OutputPath
    The path for the output MessagePack file. If not specified, uses input path with .msgpack extension.
#>
function ConvertTo-MessagePackFromBson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-MessagePackFromBson @PSBoundParameters
}
Set-Alias -Name bson-to-msgpack -Value ConvertTo-MessagePackFromBson -ErrorAction SilentlyContinue
Set-Alias -Name bson-to-messagepack -Value ConvertTo-MessagePackFromBson -ErrorAction SilentlyContinue

# Convert MessagePack to BSON
<#
.SYNOPSIS
    Converts MessagePack file to BSON format.
.DESCRIPTION
    Converts a MessagePack binary file directly to BSON format without going through JSON.
    This direct conversion is more efficient than converting through JSON.
    Requires Node.js, the bson package, and the @msgpack/msgpack package to be installed.
.PARAMETER InputPath
    The path to the MessagePack file.
.PARAMETER OutputPath
    The path for the output BSON file. If not specified, uses input path with .bson extension.
#>
function ConvertTo-BsonFromMessagePack {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-BsonFromMessagePack @PSBoundParameters
}
Set-Alias -Name msgpack-to-bson -Value ConvertTo-BsonFromMessagePack -ErrorAction SilentlyContinue
Set-Alias -Name messagepack-to-bson -Value ConvertTo-BsonFromMessagePack -ErrorAction SilentlyContinue

# Convert BSON to CBOR
<#
.SYNOPSIS
    Converts BSON file to CBOR format.
.DESCRIPTION
    Converts a BSON (Binary JSON) file directly to CBOR format without going through JSON.
    This direct conversion is more efficient than converting through JSON.
    Requires Node.js, the bson package, and the cbor package to be installed.
.PARAMETER InputPath
    The path to the BSON file.
.PARAMETER OutputPath
    The path for the output CBOR file. If not specified, uses input path with .cbor extension.
#>
function ConvertTo-CborFromBson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-CborFromBson @PSBoundParameters
}
Set-Alias -Name bson-to-cbor -Value ConvertTo-CborFromBson -ErrorAction SilentlyContinue

# Convert CBOR to BSON
<#
.SYNOPSIS
    Converts CBOR file to BSON format.
.DESCRIPTION
    Converts a CBOR (Concise Binary Object Representation) file directly to BSON format without going through JSON.
    This direct conversion is more efficient than converting through JSON.
    Requires Node.js, the bson package, and the cbor package to be installed.
.PARAMETER InputPath
    The path to the CBOR file.
.PARAMETER OutputPath
    The path for the output BSON file. If not specified, uses input path with .bson extension.
#>
function ConvertTo-BsonFromCbor {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-BsonFromCbor @PSBoundParameters
}
Set-Alias -Name cbor-to-bson -Value ConvertTo-BsonFromCbor -ErrorAction SilentlyContinue

# Convert MessagePack to CBOR
<#
.SYNOPSIS
    Converts MessagePack file to CBOR format.
.DESCRIPTION
    Converts a MessagePack binary file directly to CBOR format without going through JSON.
    This direct conversion is more efficient than converting through JSON.
    Requires Node.js, the @msgpack/msgpack package, and the cbor package to be installed.
.PARAMETER InputPath
    The path to the MessagePack file.
.PARAMETER OutputPath
    The path for the output CBOR file. If not specified, uses input path with .cbor extension.
#>
function ConvertTo-CborFromMessagePack {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-CborFromMessagePack @PSBoundParameters
}
Set-Alias -Name msgpack-to-cbor -Value ConvertTo-CborFromMessagePack -ErrorAction SilentlyContinue
Set-Alias -Name messagepack-to-cbor -Value ConvertTo-CborFromMessagePack -ErrorAction SilentlyContinue

# Convert CBOR to MessagePack
<#
.SYNOPSIS
    Converts CBOR file to MessagePack format.
.DESCRIPTION
    Converts a CBOR (Concise Binary Object Representation) file directly to MessagePack format without going through JSON.
    This direct conversion is more efficient than converting through JSON.
    Requires Node.js, the @msgpack/msgpack package, and the cbor package to be installed.
.PARAMETER InputPath
    The path to the CBOR file.
.PARAMETER OutputPath
    The path for the output MessagePack file. If not specified, uses input path with .msgpack extension.
#>
function ConvertTo-MessagePackFromCbor {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-MessagePackFromCbor @PSBoundParameters
}
Set-Alias -Name cbor-to-msgpack -Value ConvertTo-MessagePackFromCbor -ErrorAction SilentlyContinue
Set-Alias -Name cbor-to-messagepack -Value ConvertTo-MessagePackFromCbor -ErrorAction SilentlyContinue

# Binary-to-binary direct conversions (more efficient than going through JSON)
    
# BSON to MessagePack
Set-Item -Path Function:Global:_ConvertTo-MessagePackFromBson -Value {
    param([string]$InputPath, [string]$OutputPath)
    try {
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.bson$', '.msgpack' }
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw "Node.js is not available. Install Node.js to use binary format conversions."
        }
        $nodeScript = @"
try {
    const BSON = require('bson');
    const msgpack = require('@msgpack/msgpack');
    const fs = require('fs');
    const buffer = fs.readFileSync(process.argv[2]);
    let data = BSON.deserialize(buffer);
    // Unwrap arrays that were wrapped during serialization
    if (data && typeof data === 'object' && !Array.isArray(data) && data._data && Array.isArray(data._data) && Object.keys(data).length === 1) {
        data = data._data;
    }
    const packed = msgpack.encode(data);
    fs.writeFileSync(process.argv[3], packed);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: Required packages not installed. Install with: pnpm add -g bson @msgpack/msgpack');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
        $tempScript = Join-Path $env:TEMP "bson-to-msgpack-$(Get-Random).js"
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
        Write-Error "Failed to convert BSON to MessagePack: $_"
        throw
    }
} -Force

# MessagePack to BSON
Set-Item -Path Function:Global:_ConvertTo-BsonFromMessagePack -Value {
    param([string]$InputPath, [string]$OutputPath)
    try {
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.msgpack$', '.bson' }
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw "Node.js is not available. Install Node.js to use binary format conversions."
        }
        $nodeScript = @"
try {
    const BSON = require('bson');
    const msgpack = require('@msgpack/msgpack');
    const fs = require('fs');
    const buffer = fs.readFileSync(process.argv[2]);
    const data = msgpack.decode(buffer);
    // BSON.serialize doesn't support arrays as root, so wrap arrays in an object
    const dataToSerialize = Array.isArray(data) ? { _data: data } : data;
    const bson = BSON.serialize(dataToSerialize);
    fs.writeFileSync(process.argv[3], bson);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: Required packages not installed. Install with: pnpm add -g bson @msgpack/msgpack');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
        $tempScript = Join-Path $env:TEMP "msgpack-to-bson-$(Get-Random).js"
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
        Write-Error "Failed to convert MessagePack to BSON: $_"
    }
} -Force

# BSON to CBOR
Set-Item -Path Function:Global:_ConvertTo-CborFromBson -Value {
    param([string]$InputPath, [string]$OutputPath)
    try {
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.bson$', '.cbor' }
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw "Node.js is not available. Install Node.js to use binary format conversions."
        }
        $nodeScript = @"
try {
    const BSON = require('bson');
    const cbor = require('cbor');
    const fs = require('fs');
    const buffer = fs.readFileSync(process.argv[2]);
    let data = BSON.deserialize(buffer);
    // Unwrap arrays that were wrapped during serialization
    if (data && typeof data === 'object' && !Array.isArray(data) && data._data && Array.isArray(data._data) && Object.keys(data).length === 1) {
        data = data._data;
    }
    const encoded = cbor.encode(data);
    fs.writeFileSync(process.argv[3], encoded);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: Required packages not installed. Install with: pnpm add -g bson cbor');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
        $tempScript = Join-Path $env:TEMP "bson-to-cbor-$(Get-Random).js"
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
        Write-Error "Failed to convert BSON to CBOR: $_"
    }
} -Force

# CBOR to BSON
Set-Item -Path Function:Global:_ConvertTo-BsonFromCbor -Value {
    param([string]$InputPath, [string]$OutputPath)
    try {
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.cbor$', '.bson' }
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw "Node.js is not available. Install Node.js to use binary format conversions."
        }
        $nodeScript = @"
try {
    const BSON = require('bson');
    const cbor = require('cbor');
    const fs = require('fs');
    const buffer = fs.readFileSync(process.argv[2]);
    const data = cbor.decode(buffer);
    // BSON.serialize doesn't support arrays as root, so wrap arrays in an object
    const dataToSerialize = Array.isArray(data) ? { _data: data } : data;
    const bson = BSON.serialize(dataToSerialize);
    fs.writeFileSync(process.argv[3], bson);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: Required packages not installed. Install with: pnpm add -g bson cbor');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
        $tempScript = Join-Path $env:TEMP "cbor-to-bson-$(Get-Random).js"
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
        Write-Error "Failed to convert CBOR to BSON: $_"
    }
} -Force

# MessagePack to CBOR
Set-Item -Path Function:Global:_ConvertTo-CborFromMessagePack -Value {
    param([string]$InputPath, [string]$OutputPath)
    try {
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.msgpack$', '.cbor' }
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw "Node.js is not available. Install Node.js to use binary format conversions."
        }
        $nodeScript = @"
try {
    const msgpack = require('@msgpack/msgpack');
    const cbor = require('cbor');
    const fs = require('fs');
    const buffer = fs.readFileSync(process.argv[2]);
    const data = msgpack.decode(buffer);
    const encoded = cbor.encode(data);
    fs.writeFileSync(process.argv[3], encoded);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: Required packages not installed. Install with: pnpm add -g @msgpack/msgpack cbor');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
        $tempScript = Join-Path $env:TEMP "msgpack-to-cbor-$(Get-Random).js"
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
        Write-Error "Failed to convert MessagePack to CBOR: $_"
    }
} -Force

# CBOR to MessagePack
Set-Item -Path Function:Global:_ConvertTo-MessagePackFromCbor -Value {
    param([string]$InputPath, [string]$OutputPath)
    try {
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.cbor$', '.msgpack' }
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw "Node.js is not available. Install Node.js to use binary format conversions."
        }
        $nodeScript = @"
try {
    const msgpack = require('@msgpack/msgpack');
    const cbor = require('cbor');
    const fs = require('fs');
    const buffer = fs.readFileSync(process.argv[2]);
    const data = cbor.decode(buffer);
    const packed = msgpack.encode(data);
    fs.writeFileSync(process.argv[3], packed);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: Required packages not installed. Install with: pnpm add -g @msgpack/msgpack cbor');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
        $tempScript = Join-Path $env:TEMP "cbor-to-msgpack-$(Get-Random).js"
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
        Write-Error "Failed to convert CBOR to MessagePack: $_"
    }
} -Force
