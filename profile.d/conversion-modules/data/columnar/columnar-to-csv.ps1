# ===============================================
# Columnar to CSV format conversion utilities
# Parquet ↔ CSV, Arrow ↔ CSV
# ===============================================

<#
.SYNOPSIS
    Initializes columnar to CSV format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for converting between columnar formats (Parquet, Arrow)
    and CSV. This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and the parquetjs/apache-arrow packages to be installed.
#>
function Initialize-FileConversion-ColumnarToCsv {
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
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'runtime' 'NodeJs.psm1'
        if ($nodeJsModulePath -and -not [string]::IsNullOrWhiteSpace($nodeJsModulePath) -and (Test-Path -LiteralPath $nodeJsModulePath)) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
        }
    }
    # Parquet to CSV
    Set-Item -Path Function:Global:_ConvertFrom-ParquetToCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.parquet$', '.csv' }
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
        // Convert to CSV
        if (rows.length === 0) {
            fs.writeFileSync(process.argv[3], '');
            process.exit(0);
        }
        const headers = Object.keys(rows[0]);
        const csvLines = [headers.join(',')];
        for (const row of rows) {
            const values = headers.map(h => {
                const val = row[h];
                if (val === null || val === undefined) return '';
                const str = String(val);
                return str.includes(',') || str.includes('"') || str.includes('\n') ? `"${str.replace(/"/g, '""')}"` : str;
            });
            csvLines.push(values.join(','));
        }
        fs.writeFileSync(process.argv[3], csvLines.join('\n'));
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
            $tempScript = Join-Path $env:TEMP "parquet-to-csv-$(Get-Random).js"
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
            Write-Error "Failed to convert Parquet to CSV: $_"
        }
    } -Force

    # CSV to Parquet
    Set-Item -Path Function:Global:_ConvertTo-ParquetFromCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.csv$', '.parquet' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Parquet conversions."
            }
            # Convert CSV to JSON first, then JSON to Parquet
            $tempJson = Join-Path $env:TEMP "csv-to-parquet-$(Get-Random).json"
            try {
                # Use PowerShell's Import-Csv and ConvertTo-Json
                $csvData = Import-Csv -Path $InputPath -ErrorAction Stop
                $jsonContent = $csvData | ConvertTo-Json -Depth 100 -ErrorAction Stop
                Set-Content -LiteralPath $tempJson -Value $jsonContent -Encoding UTF8 -ErrorAction Stop
                _ConvertTo-ParquetFromJson -InputPath $tempJson -OutputPath $OutputPath -ErrorAction Stop
            }
            catch {
                $errorMsg = if ($_.Exception.Message -match 'MODULE_NOT_FOUND|package.*not installed|parquetjs') {
                    "parquetjs package is not installed. Install it with: pnpm add -g parquetjs"
                }
                else {
                    "Failed to convert CSV to Parquet: $_"
                }
                Write-Error $errorMsg
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert CSV to Parquet: $_"
        }
    } -Force

    # Arrow to CSV
    Set-Item -Path Function:Global:_ConvertFrom-ArrowToCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.arrow$', '.csv' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Arrow conversions."
            }
            # Convert Arrow to JSON first, then JSON to CSV
            $tempJson = Join-Path $env:TEMP "arrow-to-csv-$(Get-Random).json"
            try {
                _ConvertFrom-ArrowToJson -InputPath $InputPath -OutputPath $tempJson -ErrorAction Stop
                if (-not ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and (Test-Path -LiteralPath $tempJson))) {
                    throw "Arrow to JSON conversion failed - output file not created"
                }
                # Use PowerShell's ConvertFrom-Json and Export-Csv
                $jsonContent = Get-Content -LiteralPath $tempJson -Raw -ErrorAction Stop
                $jsonData = $jsonContent | ConvertFrom-Json -ErrorAction Stop
                if ($jsonData -is [array]) {
                    $jsonData | Export-Csv -Path $OutputPath -NoTypeInformation -ErrorAction Stop
                }
                elseif ($jsonData -is [PSCustomObject]) {
                    @($jsonData) | Export-Csv -Path $OutputPath -NoTypeInformation -ErrorAction Stop
                }
                else {
                    throw "Arrow data must be an array or object"
                }
            }
            catch {
                $errorMsg = if ($_.Exception.Message -match 'MODULE_NOT_FOUND|package.*not installed|apache-arrow') {
                    "apache-arrow package is not installed. Install it with: pnpm add -g apache-arrow"
                }
                else {
                    "Failed to convert Arrow to CSV: $_"
                }
                Write-Error $errorMsg
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert Arrow to CSV: $_"
        }
    } -Force

    # CSV to Arrow
    Set-Item -Path Function:Global:_ConvertTo-ArrowFromCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.csv$', '.arrow' }
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use Arrow conversions."
            }
            # Convert CSV to JSON first, then JSON to Arrow
            $tempJson = Join-Path $env:TEMP "csv-to-arrow-$(Get-Random).json"
            try {
                # Use PowerShell's Import-Csv and ConvertTo-Json
                $csvData = Import-Csv -Path $InputPath -ErrorAction Stop
                $jsonContent = $csvData | ConvertTo-Json -Depth 100 -ErrorAction Stop
                Set-Content -LiteralPath $tempJson -Value $jsonContent -Encoding UTF8 -ErrorAction Stop
                _ConvertTo-ArrowFromJson -InputPath $tempJson -OutputPath $OutputPath -ErrorAction Stop
            }
            catch {
                $errorMsg = if ($_.Exception.Message -match 'MODULE_NOT_FOUND|package.*not installed|apache-arrow') {
                    "apache-arrow package is not installed. Install it with: pnpm add -g apache-arrow"
                }
                else {
                    "Failed to convert CSV to Arrow: $_"
                }
                Write-Error $errorMsg
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert CSV to Arrow: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert Parquet to CSV
<#
.SYNOPSIS
    Converts Parquet file to CSV format.
.DESCRIPTION
    Converts a Parquet columnar file to CSV format for easy inspection and analysis.
    Requires Node.js and the parquetjs package to be installed.
.PARAMETER InputPath
    The path to the Parquet file.
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
#>
function ConvertFrom-ParquetToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-ParquetToCsv @PSBoundParameters
}
Set-Alias -Name parquet-to-csv -Value ConvertFrom-ParquetToCsv -ErrorAction SilentlyContinue

# Convert CSV to Parquet
<#
.SYNOPSIS
    Converts CSV file to Parquet format.
.DESCRIPTION
    Converts a CSV file to Parquet columnar format for efficient storage and querying.
    Requires Node.js and the parquetjs package to be installed.
.PARAMETER InputPath
    The path to the CSV file.
.PARAMETER OutputPath
    The path for the output Parquet file. If not specified, uses input path with .parquet extension.
#>
function ConvertTo-ParquetFromCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ParquetFromCsv @PSBoundParameters
}
Set-Alias -Name csv-to-parquet -Value ConvertTo-ParquetFromCsv -ErrorAction SilentlyContinue

# Convert Arrow to CSV
<#
.SYNOPSIS
    Converts Arrow file to CSV format.
.DESCRIPTION
    Converts an Arrow columnar file to CSV format for easy inspection and analysis.
    Requires Node.js and the apache-arrow package to be installed.
.PARAMETER InputPath
    The path to the Arrow file.
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
#>
function ConvertFrom-ArrowToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-ArrowToCsv @PSBoundParameters
}
Set-Alias -Name arrow-to-csv -Value ConvertFrom-ArrowToCsv -ErrorAction SilentlyContinue

# Convert CSV to Arrow
<#
.SYNOPSIS
    Converts CSV file to Arrow format.
.DESCRIPTION
    Converts a CSV file to Arrow columnar format for efficient in-memory analytics.
    Requires Node.js and the apache-arrow package to be installed.
.PARAMETER InputPath
    The path to the CSV file.
.PARAMETER OutputPath
    The path for the output Arrow file. If not specified, uses input path with .arrow extension.
#>
function ConvertTo-ArrowFromCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ArrowFromCsv @PSBoundParameters
}
Set-Alias -Name csv-to-arrow -Value ConvertTo-ArrowFromCsv -ErrorAction SilentlyContinue

