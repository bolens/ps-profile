# ===============================================
# ODS (OpenDocument Spreadsheet) format conversion utilities
# ODS ↔ CSV, HTML, PDF, XLSX
# ===============================================

<#
.SYNOPSIS
    Initializes ODS document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for ODS (OpenDocument Spreadsheet) format conversions.
    ODS is the OpenDocument format for spreadsheets used by LibreOffice and OpenOffice.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires pandoc or LibreOffice for conversions. ODS files use .ods extension.
#>
function Initialize-FileConversion-DocumentOfficeOds {
    # ODS to CSV
    Set-Item -Path Function:Global:_ConvertFrom-OdsToCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ods$', '.csv'
            }
            
            # Try pandoc first (if available)
            if (Get-Command pandoc -ErrorAction SilentlyContinue) {
                $errorOutput = & pandoc -f ods -t csv $InputPath -o $OutputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    return
                }
            }
            
            # Fallback to LibreOffice headless mode
            if (Get-Command libreoffice -ErrorAction SilentlyContinue) {
                $outputDir = Split-Path -Parent $OutputPath
                $errorOutput = & libreoffice --headless --convert-to csv --outdir $outputDir $InputPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    # LibreOffice creates file with same name but .csv extension
                    $inputName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
                    $libreOfficeOutput = Join-Path $outputDir "$inputName.csv"
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
            Write-Error "Failed to convert ODS to CSV: $($_.Exception.Message)"
            throw
        }
    } -Force

    # ODS to HTML
    Set-Item -Path Function:Global:_ConvertFrom-OdsToHtml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ods$', '.html'
            }
            
            $errorOutput = & pandoc -f ods -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting ODS to HTML. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert ODS to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # ODS to PDF
    Set-Item -Path Function:Global:_ConvertFrom-OdsToPdf -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ods$', '.pdf'
            }
            
            # Try pandoc first (if available)
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
            Write-Error "Failed to convert ODS to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # CSV to ODS
    Set-Item -Path Function:Global:_ConvertTo-OdsFromCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.csv$', '.ods'
            }
            
            $errorOutput = & pandoc -f csv -t ods $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting CSV to ODS. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert CSV to ODS: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Converts ODS file to CSV.
.DESCRIPTION
    Uses pandoc or LibreOffice to convert an ODS (OpenDocument Spreadsheet) file to CSV format.
.PARAMETER InputPath
    Path to the input ODS file.
.PARAMETER OutputPath
    Path for the output CSV file. If not specified, uses input path with .csv extension.
.EXAMPLE
    ConvertFrom-OdsToCsv -InputPath "spreadsheet.ods" -OutputPath "spreadsheet.csv"
#>
function ConvertFrom-OdsToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OdsToCsv -ErrorAction SilentlyContinue) {
            _ConvertFrom-OdsToCsv @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OdsToCsv not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ODS to CSV: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ods-to-csv' -Target 'ConvertFrom-OdsToCsv'
}
else {
    Set-Alias -Name ods-to-csv -Value ConvertFrom-OdsToCsv -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts ODS file to HTML.
.DESCRIPTION
    Uses pandoc to convert an ODS file to HTML format.
.PARAMETER InputPath
    Path to the input ODS file.
.PARAMETER OutputPath
    Path for the output HTML file. If not specified, uses input path with .html extension.
.EXAMPLE
    ConvertFrom-OdsToHtml -InputPath "spreadsheet.ods" -OutputPath "spreadsheet.html"
#>
function ConvertFrom-OdsToHtml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OdsToHtml -ErrorAction SilentlyContinue) {
            _ConvertFrom-OdsToHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OdsToHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ODS to HTML: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ods-to-html' -Target 'ConvertFrom-OdsToHtml'
}
else {
    Set-Alias -Name ods-to-html -Value ConvertFrom-OdsToHtml -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts ODS file to PDF.
.DESCRIPTION
    Uses pandoc or LibreOffice to convert an ODS file to PDF format.
.PARAMETER InputPath
    Path to the input ODS file.
.PARAMETER OutputPath
    Path for the output PDF file. If not specified, uses input path with .pdf extension.
.EXAMPLE
    ConvertFrom-OdsToPdf -InputPath "spreadsheet.ods" -OutputPath "spreadsheet.pdf"
#>
function ConvertFrom-OdsToPdf {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OdsToPdf -ErrorAction SilentlyContinue) {
            _ConvertFrom-OdsToPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OdsToPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ODS to PDF: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ods-to-pdf' -Target 'ConvertFrom-OdsToPdf'
}
else {
    Set-Alias -Name ods-to-pdf -Value ConvertFrom-OdsToPdf -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts CSV file to ODS.
.DESCRIPTION
    Uses pandoc to convert a CSV file to ODS (OpenDocument Spreadsheet) format.
.PARAMETER InputPath
    Path to the input CSV file.
.PARAMETER OutputPath
    Path for the output ODS file. If not specified, uses input path with .ods extension.
.EXAMPLE
    ConvertTo-OdsFromCsv -InputPath "spreadsheet.csv" -OutputPath "spreadsheet.ods"
#>
function ConvertTo-OdsFromCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-OdsFromCsv -ErrorAction SilentlyContinue) {
            _ConvertTo-OdsFromCsv @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-OdsFromCsv not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert CSV to ODS: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'csv-to-ods' -Target 'ConvertTo-OdsFromCsv'
}
else {
    Set-Alias -Name csv-to-ods -Value ConvertTo-OdsFromCsv -ErrorAction SilentlyContinue
}

