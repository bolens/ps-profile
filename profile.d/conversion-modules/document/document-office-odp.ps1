# ===============================================
# ODP (OpenDocument Presentation) format conversion utilities
# ODP ↔ HTML, PDF, PPTX
# ===============================================

<#
.SYNOPSIS
    Initializes ODP document format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for ODP (OpenDocument Presentation) format conversions.
    ODP is the OpenDocument format for presentations used by LibreOffice and OpenOffice.
    This function is called automatically by Ensure-FileConversion-Documents.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires pandoc or LibreOffice for conversions. ODP files use .odp extension.
#>
function Initialize-FileConversion-DocumentOfficeOdp {
    # ODP to HTML
    Set-Item -Path Function:Global:_ConvertFrom-OdpToHtml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.odp$', '.html'
            }
            
            $errorOutput = & pandoc -f odp -t html $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting ODP to HTML. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert ODP to HTML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # ODP to PDF
    Set-Item -Path Function:Global:_ConvertFrom-OdpToPdf -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.odp$', '.pdf'
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
            Write-Error "Failed to convert ODP to PDF: $($_.Exception.Message)"
            throw
        }
    } -Force

    # ODP to PPTX
    Set-Item -Path Function:Global:_ConvertFrom-OdpToPptx -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.odp$', '.pptx'
            }
            
            $errorOutput = & pandoc -f odp -t pptx $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting ODP to PPTX. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert ODP to PPTX: $($_.Exception.Message)"
            throw
        }
    } -Force

    # PPTX to ODP
    Set-Item -Path Function:Global:_ConvertTo-OdpFromPptx -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
                throw "pandoc command not found. Please install pandoc to use this conversion function."
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.pptx$', '.odp'
            }
            
            $errorOutput = & pandoc -f pptx -t odp $InputPath -o $OutputPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "pandoc failed with exit code $exitCode when converting PPTX to ODP. Error: $errorText"
            }
        }
        catch {
            Write-Error "Failed to convert PPTX to ODP: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Converts ODP file to HTML.
.DESCRIPTION
    Uses pandoc to convert an ODP (OpenDocument Presentation) file to HTML format.
.PARAMETER InputPath
    Path to the input ODP file.
.PARAMETER OutputPath
    Path for the output HTML file. If not specified, uses input path with .html extension.
.EXAMPLE
    ConvertFrom-OdpToHtml -InputPath "presentation.odp" -OutputPath "presentation.html"
#>
function ConvertFrom-OdpToHtml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OdpToHtml -ErrorAction SilentlyContinue) {
            _ConvertFrom-OdpToHtml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OdpToHtml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ODP to HTML: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'odp-to-html' -Target 'ConvertFrom-OdpToHtml'
}
else {
    Set-Alias -Name odp-to-html -Value ConvertFrom-OdpToHtml -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts ODP file to PDF.
.DESCRIPTION
    Uses pandoc or LibreOffice to convert an ODP file to PDF format.
.PARAMETER InputPath
    Path to the input ODP file.
.PARAMETER OutputPath
    Path for the output PDF file. If not specified, uses input path with .pdf extension.
.EXAMPLE
    ConvertFrom-OdpToPdf -InputPath "presentation.odp" -OutputPath "presentation.pdf"
#>
function ConvertFrom-OdpToPdf {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OdpToPdf -ErrorAction SilentlyContinue) {
            _ConvertFrom-OdpToPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OdpToPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ODP to PDF: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'odp-to-pdf' -Target 'ConvertFrom-OdpToPdf'
}
else {
    Set-Alias -Name odp-to-pdf -Value ConvertFrom-OdpToPdf -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts ODP file to PPTX.
.DESCRIPTION
    Uses pandoc to convert an ODP file to Microsoft PowerPoint PPTX format.
.PARAMETER InputPath
    Path to the input ODP file.
.PARAMETER OutputPath
    Path for the output PPTX file. If not specified, uses input path with .pptx extension.
.EXAMPLE
    ConvertFrom-OdpToPptx -InputPath "presentation.odp" -OutputPath "presentation.pptx"
#>
function ConvertFrom-OdpToPptx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-OdpToPptx -ErrorAction SilentlyContinue) {
            _ConvertFrom-OdpToPptx @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OdpToPptx not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ODP to PPTX: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'odp-to-pptx' -Target 'ConvertFrom-OdpToPptx'
}
else {
    Set-Alias -Name odp-to-pptx -Value ConvertFrom-OdpToPptx -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts PPTX file to ODP.
.DESCRIPTION
    Uses pandoc to convert a Microsoft PowerPoint PPTX file to ODP (OpenDocument Presentation) format.
.PARAMETER InputPath
    Path to the input PPTX file.
.PARAMETER OutputPath
    Path for the output ODP file. If not specified, uses input path with .odp extension.
.EXAMPLE
    ConvertTo-OdpFromPptx -InputPath "presentation.pptx" -OutputPath "presentation.odp"
#>
function ConvertTo-OdpFromPptx {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-OdpFromPptx -ErrorAction SilentlyContinue) {
            _ConvertTo-OdpFromPptx @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-OdpFromPptx not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert PPTX to ODP: $_" -ErrorAction SilentlyContinue
    }
}
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'pptx-to-odp' -Target 'ConvertTo-OdpFromPptx'
}
else {
    Set-Alias -Name pptx-to-odp -Value ConvertTo-OdpFromPptx -ErrorAction SilentlyContinue
}

