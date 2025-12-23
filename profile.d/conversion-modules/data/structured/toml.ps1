# ===============================================
# TOML (Tom's Obvious, Minimal Language) conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes TOML format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for TOML (Tom's Obvious, Minimal Language) format.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires PSToml module for TOML output conversions.
    
    Internal Dependencies:
    - helpers-xml.ps1: Provides Convert-JsonToXml for TOML to XML conversions
    - helpers-toon.ps1: Provides Convert-JsonToToon for TOML to TOON conversions
#>
function Initialize-FileConversion-Toml {
    # Ensure PSToml module is available for TOML output conversions
    if (-not (Get-Module -Name PSToml -ErrorAction SilentlyContinue)) {
        if (Get-Module -ListAvailable -Name PSToml -ErrorAction SilentlyContinue) {
            Import-Module PSToml -ErrorAction SilentlyContinue
        }
    }

    # TOML to JSON
    Set-Item -Path Function:Global:_ConvertFrom-TomlToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.toml$', '.json'
            }
            $json = & yq eval -o=json -p toml '.' $InputPath 2>$null
            if ($LASTEXITCODE -eq 0 -and $json) {
                $json | Set-Content -LiteralPath $OutputPath -Encoding UTF8
            }
            else {
                throw "yq command failed"
            }
        }
        catch {
            Write-Error "Failed to convert TOML to JSON: $_"
        }
    } -Force

    # JSON to TOML
    Set-Item -Path Function:Global:_ConvertTo-TomlFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.toml'
            }
            if (-not (Get-Module -Name PSToml -ErrorAction SilentlyContinue)) {
                throw "PSToml module is not available. Install it with: Install-Module PSToml"
            }
            $jsonObj = Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json
            $toml = $jsonObj | ConvertTo-Toml -Depth 100
            if (-not $toml) {
                throw "PSToml conversion failed"
            }
            Set-Content -LiteralPath $OutputPath -Value $toml -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JSON to TOML: $_"
        }
    } -Force

    # TOML to YAML
    Set-Item -Path Function:Global:_ConvertFrom-TomlToYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.toml$', '.yaml'
            }
            $yaml = & yq eval -P -p toml -o yaml '.' $InputPath 2>$null
            if ($LASTEXITCODE -eq 0 -and $yaml) {
                $yaml | Set-Content -LiteralPath $OutputPath -Encoding UTF8
            }
            else {
                throw "yq command failed"
            }
        }
        catch {
            Write-Error "Failed to convert TOML to YAML: $_"
        }
    } -Force

    # YAML to TOML
    Set-Item -Path Function:Global:_ConvertTo-TomlFromYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ya?ml$', '.toml'
            }
            if (-not (Get-Module -Name PSToml -ErrorAction SilentlyContinue)) {
                throw "PSToml module is not available. Install it with: Install-Module PSToml"
            }
            $json = & yq eval -o=json $InputPath 2>$null
            if ($LASTEXITCODE -ne 0 -or -not $json) {
                throw "yq command failed"
            }
            $jsonObj = $json | ConvertFrom-Json
            $toml = $jsonObj | ConvertTo-Toml -Depth 100
            if (-not $toml) {
                throw "PSToml conversion failed"
            }
            Set-Content -LiteralPath $OutputPath -Value $toml -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert YAML to TOML: $_"
        }
    } -Force

    # TOML to TOON
    Set-Item -Path Function:Global:_ConvertFrom-TomlToToon -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.toml$', '.toon'
            }
            $json = & yq eval -o=json -p toml '.' $InputPath 2>$null
            if ($LASTEXITCODE -eq 0 -and $json) {
                $jsonObj = $json | ConvertFrom-Json
                $toon = Convert-JsonToToon -JsonObject $jsonObj
                Set-Content -LiteralPath $OutputPath -Value $toon -Encoding UTF8
            }
            else {
                throw "yq command failed"
            }
        }
        catch {
            Write-Error "Failed to convert TOML to TOON: $_"
        }
    } -Force

    # TOON to TOML
    Set-Item -Path Function:Global:_ConvertTo-TomlFromToon -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.toon$', '.toml'
            }
            if (-not (Get-Module -Name PSToml -ErrorAction SilentlyContinue)) {
                throw "PSToml module is not available. Install it with: Install-Module PSToml"
            }
            $toon = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = Convert-ToonToJson -ToonString $toon
            $toml = $jsonObj | ConvertTo-Toml -Depth 100
            if (-not $toml) {
                throw "PSToml conversion failed"
            }
            Set-Content -LiteralPath $OutputPath -Value $toml -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert TOON to TOML: $_"
        }
    } -Force

    # TOML to XML
    Set-Item -Path Function:Global:_ConvertFrom-TomlToXml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.toml$', '.xml'
            }
            $json = & yq eval -o=json -p toml '.' $InputPath 2>$null
            if ($LASTEXITCODE -eq 0 -and $json) {
                $jsonObj = $json | ConvertFrom-Json
                $xml = Convert-JsonToXml -JsonObject $jsonObj
                $xml.Save($OutputPath)
            }
            else {
                throw "yq command failed"
            }
        }
        catch {
            Write-Error "Failed to convert TOML to XML: $_"
        }
    } -Force

    # XML to TOML
    Set-Item -Path Function:Global:_ConvertTo-TomlFromXml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.xml$', '.toml'
            }
            if (-not (Get-Module -Name PSToml -ErrorAction SilentlyContinue)) {
                throw "PSToml module is not available. Install it with: Install-Module PSToml"
            }
            $xml = [xml](Get-Content -LiteralPath $InputPath -Raw)
            $result = @{}
            $result[$xml.DocumentElement.Name] = Convert-XmlToJsonObject $xml.DocumentElement
            $jsonObj = [PSCustomObject]$result
            $toml = $jsonObj | ConvertTo-Toml -Depth 100
            if (-not $toml) {
                throw "PSToml conversion failed"
            }
            Set-Content -LiteralPath $OutputPath -Value $toml -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert XML to TOML: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert TOML to JSON
<#
.SYNOPSIS
    Converts TOML file to JSON format.
.DESCRIPTION
    Converts a TOML (Tom's Obvious, Minimal Language) file to JSON format using yq.
.PARAMETER InputPath
    The path to the TOML file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-TomlToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-TomlToJson @PSBoundParameters
}
Set-Alias -Name toml-to-json -Value ConvertFrom-TomlToJson -ErrorAction SilentlyContinue

# Convert JSON to TOML
<#
.SYNOPSIS
    Converts JSON file to TOML format.
.DESCRIPTION
    Converts a JSON file to TOML (Tom's Obvious, Minimal Language) format using yq.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output TOML file. If not specified, uses input path with .toml extension.
#>
function ConvertTo-TomlFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-TomlFromJson @PSBoundParameters
}
Set-Alias -Name json-to-toml -Value ConvertTo-TomlFromJson -ErrorAction SilentlyContinue

# Convert TOML to YAML
<#
.SYNOPSIS
    Converts TOML file to YAML format.
.DESCRIPTION
    Converts a TOML (Tom's Obvious, Minimal Language) file to YAML format using yq.
.PARAMETER InputPath
    The path to the TOML file.
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
#>
function ConvertFrom-TomlToYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-TomlToYaml @PSBoundParameters
}
Set-Alias -Name toml-to-yaml -Value ConvertFrom-TomlToYaml -ErrorAction SilentlyContinue

# Convert YAML to TOML
<#
.SYNOPSIS
    Converts YAML file to TOML format.
.DESCRIPTION
    Converts a YAML file to TOML (Tom's Obvious, Minimal Language) format using yq.
.PARAMETER InputPath
    The path to the YAML file.
.PARAMETER OutputPath
    The path for the output TOML file. If not specified, uses input path with .toml extension.
#>
function ConvertTo-TomlFromYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-TomlFromYaml @PSBoundParameters
}
Set-Alias -Name yaml-to-toml -Value ConvertTo-TomlFromYaml -ErrorAction SilentlyContinue

# Convert TOML to TOON
<#
.SYNOPSIS
    Converts TOML file to TOON format.
.DESCRIPTION
    Converts a TOML (Tom's Obvious, Minimal Language) file to TOON (Token-Oriented Object Notation) format.
.PARAMETER InputPath
    The path to the TOML file.
.PARAMETER OutputPath
    The path for the output TOON file. If not specified, uses input path with .toon extension.
#>
function ConvertFrom-TomlToToon {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-TomlToToon @PSBoundParameters
}
Set-Alias -Name toml-to-toon -Value ConvertFrom-TomlToToon -ErrorAction SilentlyContinue

# Convert TOON to TOML
<#
.SYNOPSIS
    Converts TOON file to TOML format.
.DESCRIPTION
    Converts a TOON (Token-Oriented Object Notation) file to TOML (Tom's Obvious, Minimal Language) format.
.PARAMETER InputPath
    The path to the TOON file.
.PARAMETER OutputPath
    The path for the output TOML file. If not specified, uses input path with .toml extension.
#>
function ConvertTo-TomlFromToon {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-TomlFromToon @PSBoundParameters
}
Set-Alias -Name toon-to-toml -Value ConvertTo-TomlFromToon -ErrorAction SilentlyContinue

# Convert TOML to XML
<#
.SYNOPSIS
    Converts TOML file to XML format.
.DESCRIPTION
    Converts a TOML (Tom's Obvious, Minimal Language) file to XML format.
.PARAMETER InputPath
    The path to the TOML file.
.PARAMETER OutputPath
    The path for the output XML file. If not specified, uses input path with .xml extension.
#>
function ConvertFrom-TomlToXml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-TomlToXml @PSBoundParameters
}
Set-Alias -Name toml-to-xml -Value ConvertFrom-TomlToXml -ErrorAction SilentlyContinue

# Convert XML to TOML
<#
.SYNOPSIS
    Converts XML file to TOML format.
.DESCRIPTION
    Converts an XML file to TOML (Tom's Obvious, Minimal Language) format.
.PARAMETER InputPath
    The path to the XML file.
.PARAMETER OutputPath
    The path for the output TOML file. If not specified, uses input path with .toml extension.
#>
function ConvertTo-TomlFromXml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-TomlFromXml @PSBoundParameters
}
Set-Alias -Name xml-to-toml -Value ConvertTo-TomlFromXml -ErrorAction SilentlyContinue

