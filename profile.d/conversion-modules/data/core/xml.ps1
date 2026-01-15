# ===============================================
# XML format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes XML format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for XML format conversions.
    Supports conversion from XML to JSON.
    This function is called automatically by Initialize-FileConversion-CoreBasic.
.NOTES
    This is an internal initialization function and should not be called directly.
    XML to JSON conversion uses a helper function Convert-XmlToJsonObject.
#>
function Initialize-FileConversion-CoreBasicXml {
    # XML to JSON
    Set-Item -Path Function:Global:_ConvertFrom-XmlToJson -Value { 
        param([string]$Path)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.xml.to-json] Starting conversion: $Path"
            }
            
            $convStartTime = Get-Date
            $xml = [xml](Get-Content -LiteralPath $Path -Raw)
            $result = @{}
            $result[$xml.DocumentElement.Name] = Convert-XmlToJsonObject $xml.DocumentElement
            $json = [PSCustomObject]$result | ConvertTo-Json -Depth 100
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.xml.to-json] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.xml.to-json] Root element: $($xml.DocumentElement.Name)"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $Path) { (Get-Item -LiteralPath $Path).Length } else { 0 }
                $outputLength = $json.Length
                Write-Host "  [conversion.xml.to-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputLength} characters, Root element: $($xml.DocumentElement.Name)" -ForegroundColor DarkGray
            }
            
            return $json
        } 
        catch { 
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($Path -and (Test-Path -LiteralPath $Path)) { (Get-Item -LiteralPath $Path).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.xml.to-json' -Context @{
                    input_path = $Path
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to parse XML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.xml.to-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.xml.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        } 
    } -Force
}

# Public functions and aliases
# Convert XML to JSON
<#
.SYNOPSIS
    Converts XML file to JSON format.
.DESCRIPTION
    Parses an XML file and converts it to JSON representation.
.PARAMETER Path
    The path to the XML file to convert.
#>
function ConvertFrom-XmlToJson {
    param([string]$Path)
    
    # Parse debug level once at function start
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        # Debug is enabled
    }
    
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        & "Global:_ConvertFrom-XmlToJson" @PSBoundParameters
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            $inputSize = if ($Path -and (Test-Path -LiteralPath $Path)) { (Get-Item -LiteralPath $Path).Length } else { 0 }
            Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.xml.to-json' -Context @{
                input_path = $Path
                input_size_bytes = $inputSize
                error_type = $_.Exception.GetType().FullName
            }
        }
        else {
            Write-Error "Failed to convert XML to JSON: $($_.Exception.Message)"
        }
        
        # Level 2: Error details
        if ($debugLevel -ge 2) {
            Write-Verbose "[conversion.xml.to-json] Error type: $($_.Exception.GetType().FullName)"
        }
        
        # Level 3: Stack trace
        if ($debugLevel -ge 3) {
            Write-Host "  [conversion.xml.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        }
        
        throw
    }
}
Set-Alias -Name xml-to-json -Value ConvertFrom-XmlToJson -ErrorAction SilentlyContinue

