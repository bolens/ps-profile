# ===============================================
# Arrow format conversion utilities
# JSON ↔ Arrow
# ===============================================

<#
.SYNOPSIS
    Initializes Arrow format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Apache Arrow columnar format.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and the apache-arrow package to be installed.
#>
function Initialize-FileConversion-ColumnarArrow {
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
    # JSON to Arrow
    Set-Item -Path Function:Global:_ConvertTo-ArrowFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.arrow' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Arrow conversions."
            }
            $nodeScript = @"
try {
    const arrow = require('apache-arrow');
    const fs = require('fs');
    const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    // Arrow requires table construction - simplified approach
    // For full implementation, use Arrow Table API
    console.error('Error: Arrow conversion requires table construction. Use apache-arrow library with Table API.');
    process.exit(1);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: apache-arrow package is not installed. Install it with: pnpm add -g apache-arrow');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "arrow-encode-$(Get-Random).js"
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
            Write-Error "Failed to convert JSON to Arrow: $_"
        }
    } -Force

    # Arrow to JSON
    Set-Item -Path Function:Global:_ConvertFrom-ArrowToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.arrow$', '.json' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Arrow conversions."
            }
            $nodeScript = @"
try {
    const arrow = require('apache-arrow');
    const fs = require('fs');
    const buffer = fs.readFileSync(process.argv[2]);
    const table = arrow.tableFromIPC(buffer);
    const json = JSON.stringify(table.toArray(), null, 2);
    fs.writeFileSync(process.argv[3], json);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: apache-arrow package is not installed. Install it with: pnpm add -g apache-arrow');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "arrow-decode-$(Get-Random).js"
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
            Write-Error "Failed to convert Arrow to JSON: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert JSON to Arrow
<#
.SYNOPSIS
    Converts JSON file to Arrow format.
.DESCRIPTION
    Converts a JSON file to Apache Arrow columnar format.
    Requires Node.js and the apache-arrow package to be installed.
    Note: Arrow conversion requires table construction.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output Arrow file. If not specified, uses input path with .arrow extension.
#>
function ConvertTo-ArrowFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ArrowFromJson @PSBoundParameters
}
Set-Alias -Name json-to-arrow -Value ConvertTo-ArrowFromJson -ErrorAction SilentlyContinue

# Convert Arrow to JSON
<#
.SYNOPSIS
    Converts Arrow file to JSON format.
.DESCRIPTION
    Converts an Apache Arrow columnar file back to JSON format.
    Requires Node.js and the apache-arrow package to be installed.
.PARAMETER InputPath
    The path to the Arrow file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-ArrowToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-ArrowToJson @PSBoundParameters
}
Set-Alias -Name arrow-to-json -Value ConvertFrom-ArrowToJson -ErrorAction SilentlyContinue

