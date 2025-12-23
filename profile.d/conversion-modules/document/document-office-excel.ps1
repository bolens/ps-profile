# ===============================================
# Excel format conversion utilities
# Excel (XLSX/XLS) ↔ CSV, JSON, HTML, PDF, ODS
# ===============================================

<#
.SYNOPSIS
    Initializes Excel document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Excel (XLSX/XLS) format conversions.
    Excel is Microsoft's spreadsheet format used for data storage and analysis.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires ImportExcel PowerShell module or other tools for conversions.
    Excel files use .xlsx (modern) or .xls (legacy) extensions.
#>
function Initialize-FileConversion-DocumentOfficeExcel {
    # Excel to CSV
    Set-Item -Path Function:Global:_ConvertFrom-ExcelToCsv -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SheetName = $null)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(xlsx|xls)$', '.csv'
            }
            
            # Try ImportExcel module first
            if (Get-Module -ListAvailable -Name ImportExcel) {
                Import-Module ImportExcel -ErrorAction SilentlyContinue
                if (Get-Command Import-Excel -ErrorAction SilentlyContinue) {
                    $data = if ($SheetName) {
                        Import-Excel -Path $InputPath -WorksheetName $SheetName
                    }
                    else {
                        Import-Excel -Path $InputPath
                    }
                    $data | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                    return
                }
            }
            
            # Fallback to pandoc (if available)
            if (Get-Command pandoc -ErrorAction SilentlyContinue) {
                $errorOutput = & pandoc -f xlsx -t csv $InputPath -o $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            
            throw "Neither ImportExcel module nor pandoc found. Please install ImportExcel module (Install-Module ImportExcel) or pandoc to use this conversion function."
        }
        catch {
            Write-Error "Failed to convert Excel to CSV: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Excel to JSON
    Set-Item -Path Function:Global:_ConvertFrom-ExcelToJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SheetName = $null)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(xlsx|xls)$', '.json'
            }
            
            # Try ImportExcel module first
            if (Get-Module -ListAvailable -Name ImportExcel) {
                Import-Module ImportExcel -ErrorAction SilentlyContinue
                if (Get-Command Import-Excel -ErrorAction SilentlyContinue) {
                    $data = if ($SheetName) {
                        Import-Excel -Path $InputPath -WorksheetName $SheetName
                    }
                    else {
                        Import-Excel -Path $InputPath
                    }
                    $data | ConvertTo-Json -Depth 100 | Set-Content -Path $OutputPath -Encoding UTF8
                    return
                }
            }
            
            throw "ImportExcel module not found. Please install ImportExcel module (Install-Module ImportExcel) to use this conversion function."
        }
        catch {
            Write-Error "Failed to convert Excel to JSON: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Excel to HTML
    Set-Item -Path Function:Global:_ConvertFrom-ExcelToHtml -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SheetName = $null)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(xlsx|xls)$', '.html'
            }
            
            $errorOutput = & pandoc -f xlsx -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Excel to HTML. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Excel to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Excel to PDF
    Set-Item -Path Function:Global:_ConvertFrom-ExcelToPdf -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SheetName = $null)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(xlsx|xls)$', '.pdf'
            }
            
            # Try pandoc first
            if (Get-Command pandoc -ErrorAction SilentlyContinue) {
                $errorOutput = & pandoc $InputPath -o $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            
            # Fallback to LibreOffice headless mode
            if (Get-Command libreoffice -ErrorAction SilentlyContinue) {
                $outputDir = Split-Path -Parent $OutputPath
                $errorOutput = & libreoffice --headless --convert-to pdf --outdir $outputDir $InputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    # LibreOffice creates file with same name but .pdf extension
                    $inputName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
                    $libreOfficeOutput = Join-Path $outputDir "$inputName.pdf"
                    if ($libreOfficeOutput -and -not [string]::IsNullOrWhiteSpace($libreOfficeOutput) -and (Test-Path -LiteralPath $libreOfficeOutput)) {
                        if ($libreOfficeOutput -ne $OutputPath) {
                            Move-Item -Path $libreOfficeOutput -Destination $OutputPath -Force
                        }
                        return
                    }
                }
            }
            
            throw "Neither pandoc nor LibreOffice found. Please install one of them to use this conversion function."
        }
        catch {
            Write-Error "Failed to convert Excel to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # Excel to ODS
    Set-Item -Path Function:Global:_ConvertFrom-ExcelToOds -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SheetName = $null)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(xlsx|xls)$', '.ods'
            }
            
            $errorOutput = & pandoc -f xlsx -t ods $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting Excel to ODS. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert Excel to ODS: $($_.Exception.Message)"
            throw
        }
    } -Force

    # CSV to Excel
    Set-Item -Path Function:Global:_ConvertTo-ExcelFromCsv -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SheetName = 'Sheet1')
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.csv$', '.xlsx'
            }
            
            # Try ImportExcel module first
            if (Get-Module -ListAvailable -Name ImportExcel) {
                Import-Module ImportExcel -ErrorAction SilentlyContinue
                if (Get-Command Import-Csv -ErrorAction SilentlyContinue) {
                    $data = Import-Csv -Path $InputPath
                    $data | Export-Excel -Path $OutputPath -WorksheetName $SheetName -AutoSize -FreezeTopRow
                    return
                }
            }
            
            # Fallback to pandoc
            if (Get-Command pandoc -ErrorAction SilentlyContinue) {
                $errorOutput = & pandoc -f csv -t xlsx $InputPath -o $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            
            throw "Neither ImportExcel module nor pandoc found. Please install ImportExcel module (Install-Module ImportExcel) or pandoc to use this conversion function."
        }
        catch {
            Write-Error "Failed to convert CSV to Excel: $($_.Exception.Message)"
            throw
        }
    } -Force

    # JSON to Excel
    Set-Item -Path Function:Global:_ConvertTo-ExcelFromJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SheetName = 'Sheet1')
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.xlsx'
            }
            
            # Try ImportExcel module first
            if (Get-Module -ListAvailable -Name ImportExcel) {
                Import-Module ImportExcel -ErrorAction SilentlyContinue
                if (Get-Command ConvertFrom-Json -ErrorAction SilentlyContinue) {
                    $jsonContent = Get-Content -Path $InputPath -Raw
                    $data = $jsonContent | ConvertFrom-Json
                    # Convert to array if single object
                    if ($data -isnot [System.Array]) {
                        $data = @($data)
                    }
                    $data | Export-Excel -Path $OutputPath -WorksheetName $SheetName -AutoSize -FreezeTopRow
                    return
                }
            }
            
            throw "ImportExcel module not found. Please install ImportExcel module (Install-Module ImportExcel) to use this conversion function."
        }
        catch {
            Write-Error "Failed to convert JSON to Excel: $($_.Exception.Message)"
            throw
        }
    } -Force

    # ODS to Excel
    Set-Item -Path Function:Global:_ConvertTo-ExcelFromOds -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$SheetName = $null)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ods$', '.xlsx'
            }
            
            $errorOutput = & pandoc -f ods -t xlsx $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting ODS to Excel. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert ODS to Excel: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Converts Excel file to CSV.
.DESCRIPTION
    Uses ImportExcel module or pandoc to convert an Excel (XLSX/XLS) file to CSV format.
.PARAMETER InputPath
    Path to the input Excel file.
.PARAMETER OutputPath
    Path for the output CSV file. If not specified, uses input path with .csv extension.
.PARAMETER SheetName
    Optional sheet name to convert. If not specified, converts the first sheet.
.EXAMPLE
    ConvertFrom-ExcelToCsv -InputPath "spreadsheet.xlsx" -OutputPath "spreadsheet.csv"
#>
function ConvertFrom-ExcelToCsv {
    param([string]$InputPath, [string]$OutputPath, [string]$SheetName = $null)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-ExcelToCsv -ErrorAction SilentlyContinue) {
            _ConvertFrom-ExcelToCsv @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-ExcelToCsv not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Excel to CSV: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'excel-to-csv' -Target 'ConvertFrom-ExcelToCsv'
    Set-AgentModeAlias -Name 'xlsx-to-csv' -Target 'ConvertFrom-ExcelToCsv'
    Set-AgentModeAlias -Name 'xls-to-csv' -Target 'ConvertFrom-ExcelToCsv'
}
else {
    Set-Alias -Name excel-to-csv -Value ConvertFrom-ExcelToCsv -ErrorAction SilentlyContinue
    Set-Alias -Name xlsx-to-csv -Value ConvertFrom-ExcelToCsv -ErrorAction SilentlyContinue
    Set-Alias -Name xls-to-csv -Value ConvertFrom-ExcelToCsv -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Excel file to JSON.
.DESCRIPTION
    Uses ImportExcel module to convert an Excel file to JSON format.
.PARAMETER InputPath
    Path to the input Excel file.
.PARAMETER OutputPath
    Path for the output JSON file. If not specified, uses input path with .json extension.
.PARAMETER SheetName
    Optional sheet name to convert. If not specified, converts the first sheet.
.EXAMPLE
    ConvertFrom-ExcelToJson -InputPath "spreadsheet.xlsx" -OutputPath "spreadsheet.json"
#>
function ConvertFrom-ExcelToJson {
    param([string]$InputPath, [string]$OutputPath, [string]$SheetName = $null)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-ExcelToJson -ErrorAction SilentlyContinue) {
            _ConvertFrom-ExcelToJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-ExcelToJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Excel to JSON: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'excel-to-json' -Target 'ConvertFrom-ExcelToJson'
    Set-AgentModeAlias -Name 'xlsx-to-json' -Target 'ConvertFrom-ExcelToJson'
    Set-AgentModeAlias -Name 'xls-to-json' -Target 'ConvertFrom-ExcelToJson'
}
else {
    Set-Alias -Name excel-to-json -Value ConvertFrom-ExcelToJson -ErrorAction SilentlyContinue
    Set-Alias -Name xlsx-to-json -Value ConvertFrom-ExcelToJson -ErrorAction SilentlyContinue
    Set-Alias -Name xls-to-json -Value ConvertFrom-ExcelToJson -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Excel file to HTML.
.DESCRIPTION
    Uses pandoc to convert an Excel file to HTML format.
.PARAMETER InputPath
    Path to the input Excel file.
.PARAMETER OutputPath
    Path for the output HTML file. If not specified, uses input path with .html extension.
.PARAMETER SheetName
    Optional sheet name to convert. If not specified, converts the first sheet.
.EXAMPLE
    ConvertFrom-ExcelToHtml -InputPath "spreadsheet.xlsx" -OutputPath "spreadsheet.html"
#>
function ConvertFrom-ExcelToHtml {
    param([string]$InputPath, [string]$OutputPath, [string]$SheetName = $null)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-ExcelToHtml -ErrorAction SilentlyContinue) {
            _ConvertFrom-ExcelToHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-ExcelToHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Excel to HTML: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'excel-to-html' -Target 'ConvertFrom-ExcelToHtml'
    Set-AgentModeAlias -Name 'xlsx-to-html' -Target 'ConvertFrom-ExcelToHtml'
    Set-AgentModeAlias -Name 'xls-to-html' -Target 'ConvertFrom-ExcelToHtml'
}
else {
    Set-Alias -Name excel-to-html -Value ConvertFrom-ExcelToHtml -ErrorAction SilentlyContinue
    Set-Alias -Name xlsx-to-html -Value ConvertFrom-ExcelToHtml -ErrorAction SilentlyContinue
    Set-Alias -Name xls-to-html -Value ConvertFrom-ExcelToHtml -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Excel file to PDF.
.DESCRIPTION
    Uses pandoc or LibreOffice to convert an Excel file to PDF format.
.PARAMETER InputPath
    Path to the input Excel file.
.PARAMETER OutputPath
    Path for the output PDF file. If not specified, uses input path with .pdf extension.
.PARAMETER SheetName
    Optional sheet name to convert. If not specified, converts the first sheet.
.EXAMPLE
    ConvertFrom-ExcelToPdf -InputPath "spreadsheet.xlsx" -OutputPath "spreadsheet.pdf"
#>
function ConvertFrom-ExcelToPdf {
    param([string]$InputPath, [string]$OutputPath, [string]$SheetName = $null)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-ExcelToPdf -ErrorAction SilentlyContinue) {
            _ConvertFrom-ExcelToPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-ExcelToPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Excel to PDF: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'excel-to-pdf' -Target 'ConvertFrom-ExcelToPdf'
    Set-AgentModeAlias -Name 'xlsx-to-pdf' -Target 'ConvertFrom-ExcelToPdf'
    Set-AgentModeAlias -Name 'xls-to-pdf' -Target 'ConvertFrom-ExcelToPdf'
}
else {
    Set-Alias -Name excel-to-pdf -Value ConvertFrom-ExcelToPdf -ErrorAction SilentlyContinue
    Set-Alias -Name xlsx-to-pdf -Value ConvertFrom-ExcelToPdf -ErrorAction SilentlyContinue
    Set-Alias -Name xls-to-pdf -Value ConvertFrom-ExcelToPdf -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Excel file to ODS.
.DESCRIPTION
    Uses pandoc to convert an Excel file to ODS (OpenDocument Spreadsheet) format.
.PARAMETER InputPath
    Path to the input Excel file.
.PARAMETER OutputPath
    Path for the output ODS file. If not specified, uses input path with .ods extension.
.PARAMETER SheetName
    Optional sheet name to convert. If not specified, converts the first sheet.
.EXAMPLE
    ConvertFrom-ExcelToOds -InputPath "spreadsheet.xlsx" -OutputPath "spreadsheet.ods"
#>
function ConvertFrom-ExcelToOds {
    param([string]$InputPath, [string]$OutputPath, [string]$SheetName = $null)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-ExcelToOds -ErrorAction SilentlyContinue) {
            _ConvertFrom-ExcelToOds @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-ExcelToOds not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Excel to ODS: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'excel-to-ods' -Target 'ConvertFrom-ExcelToOds'
    Set-AgentModeAlias -Name 'xlsx-to-ods' -Target 'ConvertFrom-ExcelToOds'
    Set-AgentModeAlias -Name 'xls-to-ods' -Target 'ConvertFrom-ExcelToOds'
}
else {
    Set-Alias -Name excel-to-ods -Value ConvertFrom-ExcelToOds -ErrorAction SilentlyContinue
    Set-Alias -Name xlsx-to-ods -Value ConvertFrom-ExcelToOds -ErrorAction SilentlyContinue
    Set-Alias -Name xls-to-ods -Value ConvertFrom-ExcelToOds -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts CSV file to Excel.
.DESCRIPTION
    Uses ImportExcel module or pandoc to convert a CSV file to Excel (XLSX) format.
.PARAMETER InputPath
    Path to the input CSV file.
.PARAMETER OutputPath
    Path for the output Excel file. If not specified, uses input path with .xlsx extension.
.PARAMETER SheetName
    Name for the Excel sheet (default: Sheet1).
.EXAMPLE
    ConvertTo-ExcelFromCsv -InputPath "data.csv" -OutputPath "data.xlsx" -SheetName "Data"
#>
function ConvertTo-ExcelFromCsv {
    param([string]$InputPath, [string]$OutputPath, [string]$SheetName = 'Sheet1')
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-ExcelFromCsv -ErrorAction SilentlyContinue) {
            _ConvertTo-ExcelFromCsv @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-ExcelFromCsv not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert CSV to Excel: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'csv-to-excel' -Target 'ConvertTo-ExcelFromCsv'
    Set-AgentModeAlias -Name 'csv-to-xlsx' -Target 'ConvertTo-ExcelFromCsv'
}
else {
    Set-Alias -Name csv-to-excel -Value ConvertTo-ExcelFromCsv -ErrorAction SilentlyContinue
    Set-Alias -Name csv-to-xlsx -Value ConvertTo-ExcelFromCsv -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts JSON file to Excel.
.DESCRIPTION
    Uses ImportExcel module to convert a JSON file to Excel (XLSX) format.
.PARAMETER InputPath
    Path to the input JSON file.
.PARAMETER OutputPath
    Path for the output Excel file. If not specified, uses input path with .xlsx extension.
.PARAMETER SheetName
    Name for the Excel sheet (default: Sheet1).
.EXAMPLE
    ConvertTo-ExcelFromJson -InputPath "data.json" -OutputPath "data.xlsx" -SheetName "Data"
#>
function ConvertTo-ExcelFromJson {
    param([string]$InputPath, [string]$OutputPath, [string]$SheetName = 'Sheet1')
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-ExcelFromJson -ErrorAction SilentlyContinue) {
            _ConvertTo-ExcelFromJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-ExcelFromJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JSON to Excel: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'json-to-excel' -Target 'ConvertTo-ExcelFromJson'
    Set-AgentModeAlias -Name 'json-to-xlsx' -Target 'ConvertTo-ExcelFromJson'
}
else {
    Set-Alias -Name json-to-excel -Value ConvertTo-ExcelFromJson -ErrorAction SilentlyContinue
    Set-Alias -Name json-to-xlsx -Value ConvertTo-ExcelFromJson -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts ODS file to Excel.
.DESCRIPTION
    Uses pandoc to convert an ODS (OpenDocument Spreadsheet) file to Excel (XLSX) format.
.PARAMETER InputPath
    Path to the input ODS file.
.PARAMETER OutputPath
    Path for the output Excel file. If not specified, uses input path with .xlsx extension.
.PARAMETER SheetName
    Optional sheet name to convert. If not specified, converts the first sheet.
.EXAMPLE
    ConvertTo-ExcelFromOds -InputPath "spreadsheet.ods" -OutputPath "spreadsheet.xlsx"
#>
function ConvertTo-ExcelFromOds {
    param([string]$InputPath, [string]$OutputPath, [string]$SheetName = $null)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-ExcelFromOds -ErrorAction SilentlyContinue) {
            _ConvertTo-ExcelFromOds @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-ExcelFromOds not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ODS to Excel: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ods-to-excel' -Target 'ConvertTo-ExcelFromOds'
    Set-AgentModeAlias -Name 'ods-to-xlsx' -Target 'ConvertTo-ExcelFromOds'
}
else {
    Set-Alias -Name ods-to-excel -Value ConvertTo-ExcelFromOds -ErrorAction SilentlyContinue
    Set-Alias -Name ods-to-xlsx -Value ConvertTo-ExcelFromOds -ErrorAction SilentlyContinue
}

