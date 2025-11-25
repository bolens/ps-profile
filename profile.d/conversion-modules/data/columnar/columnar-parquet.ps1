# ===============================================
# Parquet format conversion utilities
# JSON ↔ Parquet
# ===============================================

<#
.SYNOPSIS
    Initializes Parquet format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Parquet columnar format.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and the parquetjs package to be installed.
#>
function Initialize-FileConversion-ColumnarParquet {
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
    # JSON to Parquet
    Set-Item -Path Function:Global:_ConvertTo-ParquetFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.parquet' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Parquet conversions."
            }
            $nodeScript = @"
try {
    const parquet = require('parquetjs');
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    // Parquet requires schema definition - simplified approach
    // For full implementation, schema should be inferred or provided
    console.error('Error: Parquet conversion requires schema definition. Use parquetjs library with proper schema.');
    process.exit(1);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: parquetjs package is not installed. Install it with: pnpm add -g parquetjs');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "parquet-encode-$(Get-Random).js"
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
            Write-Error "Failed to convert JSON to Parquet: $_"
        }
    } -Force

    # Parquet to JSON
    Set-Item -Path Function:Global:_ConvertFrom-ParquetToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.parquet$', '.json' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Parquet conversions."
            }
            $nodeScript = @"
const parquet = require('parquetjs');
const fs = require('fs');

(async () => {
    try {
        const reader = await parquet.ParquetReader.openFile(process.argv[2]);
        const cursor = reader.getCursor();
        const rows = [];
        let row;
        while (row = await cursor.next()) {
            rows.push(row);
        }
        await reader.close();
        const json = JSON.stringify(rows, null, 2);
        fs.writeFileSync(process.argv[3], json);
    } catch (error) {
        if (error.code === 'MODULE_NOT_FOUND') {
            console.error('Error: parquetjs package is not installed. Install it with: pnpm add -g parquetjs');
        } else {
            console.error('Error:', error.message);
        }
        process.exit(1);
    }
})();
"@
            $tempScript = Join-Path $env:TEMP "parquet-decode-$(Get-Random).js"
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
            Write-Error "Failed to convert Parquet to JSON: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert JSON to Parquet
<#
.SYNOPSIS
    Converts JSON file to Parquet format.
.DESCRIPTION
    Converts a JSON file to Parquet columnar format.
    Requires Node.js and the parquetjs package to be installed.
    Note: Parquet conversion requires schema definition.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output Parquet file. If not specified, uses input path with .parquet extension.
#>
function ConvertTo-ParquetFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ParquetFromJson @PSBoundParameters
}
Set-Alias -Name json-to-parquet -Value ConvertTo-ParquetFromJson -ErrorAction SilentlyContinue

# Convert Parquet to JSON
<#
.SYNOPSIS
    Converts Parquet file to JSON format.
.DESCRIPTION
    Converts a Parquet columnar file back to JSON format.
    Requires Node.js and the parquetjs package to be installed.
.PARAMETER InputPath
    The path to the Parquet file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-ParquetToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-ParquetToJson @PSBoundParameters
}
Set-Alias -Name parquet-to-json -Value ConvertFrom-ParquetToJson -ErrorAction SilentlyContinue

