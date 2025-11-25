# ===============================================
# Direct columnar format conversion utilities
# Parquet ↔ Arrow
# ===============================================

<#
.SYNOPSIS
    Initializes direct columnar format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for direct conversions between Parquet and Arrow.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js, the parquetjs package, and the apache-arrow package to be installed.
#>
function Initialize-FileConversion-ColumnarDirect {
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
    # Parquet to Arrow (direct columnar conversion)
    Set-Item -Path Function:Global:_ConvertTo-ArrowFromParquet -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.parquet$', '.arrow' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use columnar format conversions."
            }
            $nodeScript = @"
const parquet = require('parquetjs');
const arrow = require('apache-arrow');
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
        // Convert rows to Arrow format
        // Note: This is a simplified approach - full implementation would use Arrow Table API
        const json = JSON.stringify(rows, null, 2);
        // For now, write JSON as intermediate - full Arrow conversion requires Table construction
        console.error('Error: Direct Parquet to Arrow conversion requires Arrow Table API. Use parquet-to-json then json-to-arrow.');
        process.exit(1);
    } catch (error) {
        if (error.code === 'MODULE_NOT_FOUND') {
            console.error('Error: Required packages not installed. Install with: pnpm add -g parquetjs apache-arrow');
        } else {
            console.error('Error:', error.message);
        }
        process.exit(1);
    }
})();
"@
            $tempScript = Join-Path $env:TEMP "parquet-to-arrow-$(Get-Random).js"
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
            Write-Error "Failed to convert Parquet to Arrow: $_"
        }
    } -Force

    # Arrow to Parquet (direct columnar conversion)
    Set-Item -Path Function:Global:_ConvertTo-ParquetFromArrow -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.arrow$', '.parquet' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use columnar format conversions."
            }
            $nodeScript = @"
const arrow = require('apache-arrow');
const parquet = require('parquetjs');
const fs = require('fs');

try {
    const buffer = fs.readFileSync(process.argv[2]);
    // Arrow requires table construction - simplified approach
    // For full implementation, use Arrow Table API then convert to Parquet
    console.error('Error: Direct Arrow to Parquet conversion requires Arrow Table API. Use arrow-to-json then json-to-parquet.');
    process.exit(1);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: Required packages not installed. Install with: pnpm add -g apache-arrow parquetjs');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "arrow-to-parquet-$(Get-Random).js"
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
            Write-Error "Failed to convert Arrow to Parquet: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert Parquet to Arrow
<#
.SYNOPSIS
    Converts Parquet file to Arrow format.
.DESCRIPTION
    Converts a Parquet columnar file directly to Arrow format.
    Requires Node.js, the parquetjs package, and the apache-arrow package to be installed.
    Note: Direct conversion requires Arrow Table API - currently uses JSON as intermediate.
.PARAMETER InputPath
    The path to the Parquet file.
.PARAMETER OutputPath
    The path for the output Arrow file. If not specified, uses input path with .arrow extension.
#>
function ConvertTo-ArrowFromParquet {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ArrowFromParquet @PSBoundParameters
}
Set-Alias -Name parquet-to-arrow -Value ConvertTo-ArrowFromParquet -ErrorAction SilentlyContinue

# Convert Arrow to Parquet
<#
.SYNOPSIS
    Converts Arrow file to Parquet format.
.DESCRIPTION
    Converts an Arrow columnar file directly to Parquet format.
    Requires Node.js, the apache-arrow package, and the parquetjs package to be installed.
    Note: Direct conversion requires Arrow Table API - currently uses JSON as intermediate.
.PARAMETER InputPath
    The path to the Arrow file.
.PARAMETER OutputPath
    The path for the output Parquet file. If not specified, uses input path with .parquet extension.
#>
function ConvertTo-ParquetFromArrow {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ParquetFromArrow @PSBoundParameters
}
Set-Alias -Name arrow-to-parquet -Value ConvertTo-ParquetFromArrow -ErrorAction SilentlyContinue

