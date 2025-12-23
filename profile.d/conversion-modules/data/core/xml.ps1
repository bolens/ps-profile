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
        try { 
            $xml = [xml](Get-Content -LiteralPath $Path -Raw)
            $result = @{}
            $result[$xml.DocumentElement.Name] = Convert-XmlToJsonObject $xml.DocumentElement
            [PSCustomObject]$result | ConvertTo-Json -Depth 100 
        } 
        catch { 
            Write-Error "Failed to parse XML: $_" 
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
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        & "Global:_ConvertFrom-XmlToJson" @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert XML to JSON: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name xml-to-json -Value ConvertFrom-XmlToJson -ErrorAction SilentlyContinue

