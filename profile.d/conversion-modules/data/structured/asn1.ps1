# ===============================================
# ASN.1 (Abstract Syntax Notation One) format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes ASN.1 format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for ASN.1 (Abstract Syntax Notation One) format.
    ASN.1 is a standard interface description language for defining data structures.
    Supports conversions between ASN.1 schema definitions and JSON, XML formats.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    ASN.1 format structure:
    - Module definitions: ModuleName DEFINITIONS ::= BEGIN ... END
    - Type definitions: TypeName ::= TypeSpecification
    - Common types: INTEGER, OCTET STRING, SEQUENCE, CHOICE, etc.
    - Supports basic ASN.1 text notation parsing
    Reference: ITU-T X.680 series (ASN.1 standards)
#>
function Initialize-FileConversion-Asn1 {
    # Helper function to parse ASN.1 type definition
    Set-Item -Path Function:Global:_Parse-Asn1Type -Value {
        param([string]$TypeSpec)
        if ([string]::IsNullOrWhiteSpace($TypeSpec)) {
            return $null
        }
        
        $typeSpec = $TypeSpec.Trim()
        $result = @{
            Type       = 'UNKNOWN'
            Value      = $null
            Components = @()
        }
        
        # INTEGER
        if ($typeSpec -match '^\s*INTEGER\s*(?:\(([^)]+)\))?\s*$') {
            $result.Type = 'INTEGER'
            if ($matches[1]) {
                $result.Value = $matches[1]
            }
        }
        # OCTET STRING
        elseif ($typeSpec -match '^\s*OCTET\s+STRING\s*(?:\(([^)]+)\))?\s*$') {
            $result.Type = 'OCTET STRING'
            if ($matches[1]) {
                $result.Value = $matches[1]
            }
        }
        # SEQUENCE
        elseif ($typeSpec -match '^\s*SEQUENCE\s*\{') {
            $result.Type = 'SEQUENCE'
            # Extract components (simplified - handles basic cases)
            if ($typeSpec -match '\{([^}]+)\}') {
                $componentsStr = $matches[1]
                $components = $componentsStr -split ',', 0, 'Regex'
                foreach ($comp in $components) {
                    $comp = $comp.Trim()
                    if (-not [string]::IsNullOrWhiteSpace($comp)) {
                        if ($comp -match '^(\w+)\s+(\w+(?:\s+\w+)*)') {
                            $result.Components += @{
                                Name = $matches[1]
                                Type = $matches[2]
                            }
                        }
                    }
                }
            }
        }
        # CHOICE
        elseif ($typeSpec -match '^\s*CHOICE\s*\{') {
            $result.Type = 'CHOICE'
            if ($typeSpec -match '\{([^}]+)\}') {
                $componentsStr = $matches[1]
                $components = $componentsStr -split ',', 0, 'Regex'
                foreach ($comp in $components) {
                    $comp = $comp.Trim()
                    if (-not [string]::IsNullOrWhiteSpace($comp)) {
                        if ($comp -match '^(\w+)\s+(\w+(?:\s+\w+)*)') {
                            $result.Components += @{
                                Name = $matches[1]
                                Type = $matches[2]
                            }
                        }
                    }
                }
            }
        }
        # Named type reference
        elseif ($typeSpec -match '^\s*(\w+)\s*$') {
            $result.Type = 'REFERENCE'
            $result.Value = $matches[1]
        }
        # Tagged type
        elseif ($typeSpec -match '^\s*\[\s*(\d+)\s*\]\s*(.+)$') {
            $result.Type = 'TAGGED'
            $result.Tag = $matches[1]
            $innerType = _Parse-Asn1Type -TypeSpec $matches[2]
            if ($innerType) {
                $result.InnerType = $innerType
            }
        }
        else {
            $result.Type = 'UNKNOWN'
            $result.Value = $typeSpec
        }
        
        return $result
    } -Force

    # Helper function to parse ASN.1 module
    Set-Item -Path Function:Global:_Parse-Asn1Module -Value {
        param([string]$Asn1Content)
        if ([string]::IsNullOrWhiteSpace($Asn1Content)) {
            return $null
        }
        
        $result = @{
            ModuleName = ''
            Types      = @()
        }
        
        # Extract module name
        if ($Asn1Content -match '(\w+)\s+DEFINITIONS\s*::=\s*BEGIN') {
            $result.ModuleName = $matches[1]
        }
        
        # Extract type definitions (simplified parser)
        # Pattern: TypeName ::= TypeSpecification
        $typePattern = '(\w+)\s*::=\s*([^;]+);'
        $matches = [regex]::Matches($Asn1Content, $typePattern)
        
        foreach ($match in $matches) {
            $typeName = $match.Groups[1].Value
            $typeSpec = $match.Groups[2].Value.Trim()
            
            $parsedType = _Parse-Asn1Type -TypeSpec $typeSpec
            if ($parsedType) {
                $typeDef = @{
                    Name          = $typeName
                    Specification = $parsedType
                }
                $result.Types += $typeDef
            }
        }
        
        return $result
    } -Force

    # ASN.1 to JSON
    Set-Item -Path Function:Global:_ConvertFrom-Asn1ToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(asn1|asn)$', '.json'
            }
            
            $asn1Content = Get-Content -LiteralPath $InputPath -Raw
            $module = _Parse-Asn1Module -Asn1Content $asn1Content
            
            # Convert to structured format
            $result = @{
                Module = @{
                    Name  = $module.ModuleName
                    Types = @()
                }
            }
            
            foreach ($type in $module.Types) {
                $typeObj = @{
                    Name          = $type.Name
                    Type          = $type.Specification.Type
                    Specification = $type.Specification
                }
                $result.Module.Types += $typeObj
            }
            
            # Convert to JSON
            $jsonObj = [PSCustomObject]$result
            $json = $jsonObj | ConvertTo-Json -Depth 100
            Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert ASN.1 to JSON: $_"
            throw
        }
    } -Force

    # JSON to ASN.1
    Set-Item -Path Function:Global:_ConvertTo-Asn1FromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.asn1'
            }
            
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            $asn1Lines = @()
            
            # Build ASN.1 module
            $moduleName = if ($jsonObj.Module.Name) { $jsonObj.Module.Name } else { 'Module' }
            $asn1Lines += "$moduleName DEFINITIONS ::= BEGIN"
            $asn1Lines += ''
            
            # Process types
            if ($jsonObj.Module.Types) {
                foreach ($type in $jsonObj.Module.Types) {
                    $typeName = $type.Name
                    $typeSpec = $type.Specification
                    
                    # Build type specification string
                    $specStr = ''
                    if ($typeSpec.Type -eq 'INTEGER') {
                        $specStr = 'INTEGER'
                        if ($typeSpec.Value) {
                            $specStr += " ($($typeSpec.Value))"
                        }
                    }
                    elseif ($typeSpec.Type -eq 'OCTET STRING') {
                        $specStr = 'OCTET STRING'
                        if ($typeSpec.Value) {
                            $specStr += " ($($typeSpec.Value))"
                        }
                    }
                    elseif ($typeSpec.Type -eq 'SEQUENCE') {
                        $specStr = 'SEQUENCE {'
                        if ($typeSpec.Components -and $typeSpec.Components.Count -gt 0) {
                            $components = @()
                            foreach ($comp in $typeSpec.Components) {
                                $components += "    $($comp.Name) $($comp.Type)"
                            }
                            $specStr += "`r`n" + ($components -join ",`r`n")
                        }
                        $specStr += '}'
                    }
                    elseif ($typeSpec.Type -eq 'CHOICE') {
                        $specStr = 'CHOICE {'
                        if ($typeSpec.Components -and $typeSpec.Components.Count -gt 0) {
                            $components = @()
                            foreach ($comp in $typeSpec.Components) {
                                $components += "    $($comp.Name) $($comp.Type)"
                            }
                            $specStr += "`r`n" + ($components -join ",`r`n")
                        }
                        $specStr += '}'
                    }
                    elseif ($typeSpec.Type -eq 'REFERENCE') {
                        $specStr = $typeSpec.Value
                    }
                    else {
                        $specStr = $typeSpec.Value
                    }
                    
                    $asn1Lines += "$typeName ::= $specStr"
                    $asn1Lines += ''
                }
            }
            
            $asn1Lines += 'END'
            
            $asn1Content = $asn1Lines -join "`r`n"
            Set-Content -LiteralPath $OutputPath -Value $asn1Content -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JSON to ASN.1: $_"
            throw
        }
    } -Force

    # ASN.1 to XML
    Set-Item -Path Function:Global:_ConvertFrom-Asn1ToXml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(asn1|asn)$', '.xml'
            }
            
            $asn1Content = Get-Content -LiteralPath $InputPath -Raw
            $module = _Parse-Asn1Module -Asn1Content $asn1Content
            
            # Build XML
            $xmlLines = @()
            $xmlLines += '<?xml version="1.0" encoding="UTF-8"?>'
            $xmlLines += '<ASN1>'
            $xmlLines += "  <Module Name=`"$($module.ModuleName)`">"
            
            foreach ($type in $module.Types) {
                $xmlLines += "    <Type Name=`"$($type.Name)`">"
                $xmlLines += "      <TypeSpec Type=`"$($type.Specification.Type)`">"
                
                if ($type.Specification.Value) {
                    $xmlLines += "        <Value>$([System.Security.SecurityElement]::Escape($type.Specification.Value))</Value>"
                }
                
                if ($type.Specification.Components -and $type.Specification.Components.Count -gt 0) {
                    $xmlLines += "      <Components>"
                    foreach ($comp in $type.Specification.Components) {
                        $xmlLines += "        <Component Name=`"$($comp.Name)`" Type=`"$($comp.Type)`" />"
                    }
                    $xmlLines += "      </Components>"
                }
                
                $xmlLines += "      </TypeSpec>"
                $xmlLines += "    </Type>"
            }
            
            $xmlLines += "  </Module>"
            $xmlLines += '</ASN1>'
            
            $xmlContent = $xmlLines -join "`r`n"
            Set-Content -LiteralPath $OutputPath -Value $xmlContent -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert ASN.1 to XML: $_"
            throw
        }
    } -Force
}

# Convert ASN.1 to JSON
<#
.SYNOPSIS
    Converts ASN.1 schema file to JSON format.
.DESCRIPTION
    Parses an ASN.1 (Abstract Syntax Notation One) schema definition file and converts it to structured JSON format.
    Supports basic ASN.1 types: INTEGER, OCTET STRING, SEQUENCE, CHOICE, etc.
.PARAMETER InputPath
    The path to the ASN.1 file (.asn1 or .asn extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.EXAMPLE
    ConvertFrom-Asn1ToJson -InputPath "schema.asn1"
    
    Converts schema.asn1 to schema.json.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-Asn1ToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertFrom-Asn1ToJson -ErrorAction SilentlyContinue) {
            _ConvertFrom-Asn1ToJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-Asn1ToJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ASN.1 to JSON: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name asn1-to-json -Value ConvertFrom-Asn1ToJson -ErrorAction SilentlyContinue

# Convert JSON to ASN.1
<#
.SYNOPSIS
    Converts JSON file to ASN.1 format.
.DESCRIPTION
    Converts a structured JSON file (with ASN.1 module structure) to ASN.1 schema definition format.
    The JSON should have a Module structure with Types containing Name and Specification.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output ASN.1 file. If not specified, uses input path with .asn1 extension.
.EXAMPLE
    ConvertTo-Asn1FromJson -InputPath "schema.json"
    
    Converts schema.json to schema.asn1.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-Asn1FromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertTo-Asn1FromJson -ErrorAction SilentlyContinue) {
            _ConvertTo-Asn1FromJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-Asn1FromJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JSON to ASN.1: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name json-to-asn1 -Value ConvertTo-Asn1FromJson -ErrorAction SilentlyContinue

# Convert ASN.1 to XML
<#
.SYNOPSIS
    Converts ASN.1 schema file to XML format.
.DESCRIPTION
    Parses an ASN.1 schema definition file and converts it to structured XML format.
    Each type becomes an XML element with TypeSpec and Components.
.PARAMETER InputPath
    The path to the ASN.1 file (.asn1 or .asn extension).
.PARAMETER OutputPath
    The path for the output XML file. If not specified, uses input path with .xml extension.
.EXAMPLE
    ConvertFrom-Asn1ToXml -InputPath "schema.asn1"
    
    Converts schema.asn1 to schema.xml.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-Asn1ToXml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertFrom-Asn1ToXml -ErrorAction SilentlyContinue) {
            _ConvertFrom-Asn1ToXml @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-Asn1ToXml not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ASN.1 to XML: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name asn1-to-xml -Value ConvertFrom-Asn1ToXml -ErrorAction SilentlyContinue

