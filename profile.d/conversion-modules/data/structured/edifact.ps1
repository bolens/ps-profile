# ===============================================
# EDIFACT (Electronic Data Interchange) format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes EDIFACT format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for EDIFACT (Electronic Data Interchange For Administration, Commerce and Transport) format.
    EDIFACT is a UN/ECE standard for electronic data interchange used in business transactions.
    Supports conversions between EDIFACT and JSON, XML, CSV formats.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    EDIFACT format structure:
    - Segments are separated by apostrophes (')
    - Elements within segments are separated by plus signs (+)
    - Components within elements are separated by colons (:)
    - Typical message structure: UNB (Interchange Header) ... UNZ (Interchange Trailer)
    - Common segments: UNB, UNH, BGM, DTM, NAD, LIN, etc.
    Reference: UN/EDIFACT standard
#>
function Initialize-FileConversion-Edifact {
    # Helper function to parse EDIFACT segment
    Set-Item -Path Function:Global:_Parse-EdifactSegment -Value {
        param([string]$Segment)
        if ([string]::IsNullOrWhiteSpace($Segment)) {
            return $null
        }
        
        # Split by + to get elements
        $elements = $Segment -split '\+', 0, 'Regex'
        if ($elements.Count -eq 0) {
            return $null
        }
        
        $segmentTag = $elements[0]
        $parsedSegment = @{
            Tag      = $segmentTag
            Elements = @()
        }
        
        # Parse each element (skip tag, it's already captured)
        for ($i = 1; $i -lt $elements.Count; $i++) {
            $element = $elements[$i]
            # Split by : to get components
            $components = $element -split ':', 0, 'Regex'
            if ($components.Count -eq 1) {
                $parsedSegment.Elements += $components[0]
            }
            else {
                $parsedSegment.Elements += $components
            }
        }
        
        return $parsedSegment
    } -Force

    # Helper function to parse EDIFACT message
    Set-Item -Path Function:Global:_Parse-EdifactMessage -Value {
        param([string]$EdifactContent)
        if ([string]::IsNullOrWhiteSpace($EdifactContent)) {
            return @()
        }
        
        # Remove whitespace and split by apostrophe (segment terminator)
        $cleaned = $EdifactContent -replace '\s+', ' '
        $segments = $cleaned -split "'", 0, 'Regex'
        
        $parsedSegments = @()
        foreach ($segment in $segments) {
            $segment = $segment.Trim()
            if ([string]::IsNullOrWhiteSpace($segment)) {
                continue
            }
            $parsed = _Parse-EdifactSegment -Segment $segment
            if ($null -ne $parsed) {
                $parsedSegments += $parsed
            }
        }
        
        return $parsedSegments
    } -Force

    # Helper function to build EDIFACT segment
    Set-Item -Path Function:Global:_Build-EdifactSegment -Value {
        param([hashtable]$Segment)
        if ($null -eq $Segment -or -not $Segment.ContainsKey('Tag')) {
            return ''
        }
        
        $result = $Segment.Tag
        if ($Segment.ContainsKey('Elements') -and $Segment.Elements.Count -gt 0) {
            foreach ($element in $Segment.Elements) {
                $result += '+'
                if ($element -is [System.Array]) {
                    $result += $element -join ':'
                }
                else {
                    $result += $element
                }
            }
        }
        
        return $result
    } -Force

    # EDIFACT to JSON
    Set-Item -Path Function:Global:_ConvertFrom-EdifactToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(edifact|edi|edf)$', '.json'
            }
            
            $edifactContent = Get-Content -LiteralPath $InputPath -Raw
            $segments = _Parse-EdifactMessage -EdifactContent $edifactContent
            
            # Convert to structured format
            $result = @{
                Interchange = @{
                    Segments = @()
                }
            }
            
            foreach ($segment in $segments) {
                $segmentObj = @{
                    Tag      = $segment.Tag
                    Elements = $segment.Elements
                }
                $result.Interchange.Segments += $segmentObj
            }
            
            # Convert to JSON
            $jsonObj = [PSCustomObject]$result
            $json = $jsonObj | ConvertTo-Json -Depth 100
            Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert EDIFACT to JSON: $_"
            throw
        }
    } -Force

    # JSON to EDIFACT
    Set-Item -Path Function:Global:_ConvertTo-EdifactFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.edifact'
            }
            
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            $edifactLines = @()
            
            # Process segments
            if ($jsonObj.Interchange -and $jsonObj.Interchange.Segments) {
                foreach ($segment in $jsonObj.Interchange.Segments) {
                    $segmentHash = @{
                        Tag      = $segment.Tag
                        Elements = @()
                    }
                    
                    if ($segment.Elements) {
                        foreach ($element in $segment.Elements) {
                            if ($element -is [System.Array]) {
                                $segmentHash.Elements += $element
                            }
                            else {
                                $segmentHash.Elements += $element
                            }
                        }
                    }
                    
                    $segmentLine = _Build-EdifactSegment -Segment $segmentHash
                    if ($segmentLine) {
                        $edifactLines += $segmentLine
                    }
                }
            }
            
            # Join segments with apostrophe delimiter
            $edifactContent = $edifactLines -join "'" + "'"
            Set-Content -LiteralPath $OutputPath -Value $edifactContent -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JSON to EDIFACT: $_"
            throw
        }
    } -Force

    # EDIFACT to XML
    Set-Item -Path Function:Global:_ConvertFrom-EdifactToXml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(edifact|edi|edf)$', '.xml'
            }
            
            $edifactContent = Get-Content -LiteralPath $InputPath -Raw
            $segments = _Parse-EdifactMessage -EdifactContent $edifactContent
            
            # Build XML
            $xmlLines = @()
            $xmlLines += '<?xml version="1.0" encoding="UTF-8"?>'
            $xmlLines += '<EDIFACT>'
            $xmlLines += '  <Interchange>'
            
            foreach ($segment in $segments) {
                $xmlLines += "    <Segment Tag=`"$($segment.Tag)`">"
                for ($i = 0; $i -lt $segment.Elements.Count; $i++) {
                    $element = $segment.Elements[$i]
                    if ($element -is [System.Array]) {
                        $xmlLines += "      <Element Index=`"$i`">"
                        for ($j = 0; $j -lt $element.Count; $j++) {
                            $component = $element[$j]
                            $xmlLines += "        <Component Index=`"$j`">$([System.Security.SecurityElement]::Escape($component))</Component>"
                        }
                        $xmlLines += "      </Element>"
                    }
                    else {
                        $xmlLines += "      <Element Index=`"$i`">$([System.Security.SecurityElement]::Escape($element))</Element>"
                    }
                }
                $xmlLines += "    </Segment>"
            }
            
            $xmlLines += '  </Interchange>'
            $xmlLines += '</EDIFACT>'
            
            $xmlContent = $xmlLines -join "`r`n"
            Set-Content -LiteralPath $OutputPath -Value $xmlContent -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert EDIFACT to XML: $_"
            throw
        }
    } -Force

    # EDIFACT to CSV (simplified - one segment per row)
    Set-Item -Path Function:Global:_ConvertFrom-EdifactToCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(edifact|edi|edf)$', '.csv'
            }
            
            $edifactContent = Get-Content -LiteralPath $InputPath -Raw
            $segments = _Parse-EdifactMessage -EdifactContent $edifactContent
            
            # Build CSV (simplified format: Tag,Element1,Element2,...)
            $csvLines = @()
            $csvLines += 'Segment,Element1,Element2,Element3,Element4,Element5'
            
            foreach ($segment in $segments) {
                $row = @($segment.Tag)
                foreach ($element in $segment.Elements) {
                    if ($element -is [System.Array]) {
                        $row += $element -join ':'
                    }
                    else {
                        $row += $element
                    }
                }
                # Pad to at least 5 elements for consistency
                while ($row.Count -lt 6) {
                    $row += ''
                }
                $csvLines += ($row -join ',')
            }
            
            $csvContent = $csvLines -join "`r`n"
            Set-Content -LiteralPath $OutputPath -Value $csvContent -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert EDIFACT to CSV: $_"
            throw
        }
    } -Force
}

# Convert EDIFACT to JSON
<#
.SYNOPSIS
    Converts EDIFACT file to JSON format.
.DESCRIPTION
    Parses an EDIFACT (Electronic Data Interchange) file and converts it to structured JSON format.
    EDIFACT segments are converted to a structured format with tags and elements.
.PARAMETER InputPath
    The path to the EDIFACT file (.edifact, .edi, or .edf extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.EXAMPLE
    ConvertFrom-EdifactToJson -InputPath "message.edifact"
    
    Converts message.edifact to message.json.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-EdifactToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertFrom-EdifactToJson -ErrorAction SilentlyContinue) {
            _ConvertFrom-EdifactToJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-EdifactToJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert EDIFACT to JSON: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name edifact-to-json -Value ConvertFrom-EdifactToJson -ErrorAction SilentlyContinue

# Convert JSON to EDIFACT
<#
.SYNOPSIS
    Converts JSON file to EDIFACT format.
.DESCRIPTION
    Converts a structured JSON file (with EDIFACT segment structure) to EDIFACT format.
    The JSON should have an Interchange.Segments structure with Tag and Elements.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output EDIFACT file. If not specified, uses input path with .edifact extension.
.EXAMPLE
    ConvertTo-EdifactFromJson -InputPath "message.json"
    
    Converts message.json to message.edifact.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-EdifactFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertTo-EdifactFromJson -ErrorAction SilentlyContinue) {
            _ConvertTo-EdifactFromJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-EdifactFromJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JSON to EDIFACT: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name json-to-edifact -Value ConvertTo-EdifactFromJson -ErrorAction SilentlyContinue

# Convert EDIFACT to XML
<#
.SYNOPSIS
    Converts EDIFACT file to XML format.
.DESCRIPTION
    Parses an EDIFACT file and converts it to structured XML format.
    Each segment becomes an XML element with Tag attribute and Element children.
.PARAMETER InputPath
    The path to the EDIFACT file (.edifact, .edi, or .edf extension).
.PARAMETER OutputPath
    The path for the output XML file. If not specified, uses input path with .xml extension.
.EXAMPLE
    ConvertFrom-EdifactToXml -InputPath "message.edifact"
    
    Converts message.edifact to message.xml.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-EdifactToXml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertFrom-EdifactToXml -ErrorAction SilentlyContinue) {
            _ConvertFrom-EdifactToXml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-EdifactToXml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert EDIFACT to XML: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name edifact-to-xml -Value ConvertFrom-EdifactToXml -ErrorAction SilentlyContinue

# Convert EDIFACT to CSV
<#
.SYNOPSIS
    Converts EDIFACT file to CSV format.
.DESCRIPTION
    Converts an EDIFACT file to a simplified CSV format where each segment becomes a row.
    Format: Segment,Element1,Element2,Element3,Element4,Element5
.PARAMETER InputPath
    The path to the EDIFACT file (.edifact, .edi, or .edf extension).
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
.EXAMPLE
    ConvertFrom-EdifactToCsv -InputPath "message.edifact"
    
    Converts message.edifact to message.csv.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-EdifactToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertFrom-EdifactToCsv -ErrorAction SilentlyContinue) {
            _ConvertFrom-EdifactToCsv @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-EdifactToCsv not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert EDIFACT to CSV: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name edifact-to-csv -Value ConvertFrom-EdifactToCsv -ErrorAction SilentlyContinue

