# ===============================================
# TOON (Token-Oriented Object Notation) conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes TOON format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for TOON (Token-Oriented Object Notation) format.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-Toon {
    # JSON to TOON helper
    Set-Item -Path Function:Global:_ConvertTo-ToonFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.toon' }
            $json = Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json
            $toon = Convert-JsonToToon -JsonObject $json
            Set-Content -LiteralPath $OutputPath -Value $toon -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JSON to TOON: $_"
        }
    } -Force

    # TOON to JSON helper
    Set-Item -Path Function:Global:_ConvertFrom-ToonToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.toon$', '.json' }
            $toon = Get-Content -LiteralPath $InputPath -Raw
            $json = Convert-ToonToJson -ToonString $toon
            $json | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert TOON to JSON: $_"
        }
    } -Force

    # TOON to YAML
    Set-Item -Path Function:Global:_ConvertFrom-ToonToYaml -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.toon$', '.yaml' }; $json = Get-Content -LiteralPath $InputPath -Raw; $jsonObj = Convert-ToonToJson -ToonString $json; $jsonObj | ConvertTo-Json -Depth 100 | & yq eval -P | Out-File -FilePath $OutputPath -Encoding UTF8 } catch { Write-Error "Failed to convert TOON to YAML: $_" } } -Force

    # YAML to TOON
    Set-Item -Path Function:Global:_ConvertTo-ToonFromYaml -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.ya?ml$', '.toon' }; $json = & yq eval -o=json $InputPath 2>$null; if ($LASTEXITCODE -eq 0 -and $json) { $jsonObj = $json | ConvertFrom-Json; $toon = Convert-JsonToToon -JsonObject $jsonObj; Set-Content -LiteralPath $OutputPath -Value $toon -Encoding UTF8 } } catch { Write-Error "Failed to convert YAML to TOON: $_" } } -Force

    # TOON to CSV
    Set-Item -Path Function:Global:_ConvertFrom-ToonToCsv -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.toon$', '.csv' }; $json = Get-Content -LiteralPath $InputPath -Raw; $jsonObj = Convert-ToonToJson -ToonString $json; $data = $jsonObj | ConvertTo-Json -Depth 100 | ConvertFrom-Json; if ($data -is [array]) { $data | Export-Csv -NoTypeInformation -Path $OutputPath } elseif ($data -is [PSCustomObject]) { @($data) | Export-Csv -NoTypeInformation -Path $OutputPath } else { Write-Error "TOON must represent an array of objects or a single object" } } catch { Write-Error "Failed to convert TOON to CSV: $_" } } -Force

    # CSV to TOON
    Set-Item -Path Function:Global:_ConvertTo-ToonFromCsv -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.csv$', '.toon' }; $data = Import-Csv -Path $InputPath; $jsonObj = $data | ConvertTo-Json -Depth 10 | ConvertFrom-Json; $toon = Convert-JsonToToon -JsonObject $jsonObj; Set-Content -LiteralPath $OutputPath -Value $toon -Encoding UTF8 } catch { Write-Error "Failed to convert CSV to TOON: $_" } } -Force

    # TOON to XML
    Set-Item -Path Function:Global:_ConvertFrom-ToonToXml -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.toon$', '.xml' }; $json = Get-Content -LiteralPath $InputPath -Raw; $jsonObj = Convert-ToonToJson -ToonString $json; $xml = Convert-JsonToXml -JsonObject $jsonObj; $xml.Save($OutputPath) } catch { Write-Error "Failed to convert TOON to XML: $_" } } -Force

    # XML to TOON
    Set-Item -Path Function:Global:_ConvertTo-ToonFromXml -Value { param([string]$InputPath, [string]$OutputPath) try { if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.xml$', '.toon' }; $xml = [xml](Get-Content -LiteralPath $InputPath -Raw); $result = @{}; $result[$xml.DocumentElement.Name] = Convert-XmlToJsonObject $xml.DocumentElement; $jsonObj = [PSCustomObject]$result; $toon = Convert-JsonToToon -JsonObject $jsonObj; Set-Content -LiteralPath $OutputPath -Value $toon -Encoding UTF8 } catch { Write-Error "Failed to convert XML to TOON: $_" } } -Force
}

# Public functions and aliases
# Convert JSON to TOON
<#
.SYNOPSIS
    Converts JSON file to TOON format.
.DESCRIPTION
    Converts a JSON file to TOON (Token-Oriented Object Notation) format, which removes redundant JSON syntax to reduce token usage in LLMs.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output TOON file. If not specified, uses input path with .toon extension.
#>
function ConvertTo-ToonFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ToonFromJson @PSBoundParameters
}
Set-Alias -Name json-to-toon -Value ConvertTo-ToonFromJson -ErrorAction SilentlyContinue

# Convert TOON to JSON
<#
.SYNOPSIS
    Converts TOON file to JSON format.
.DESCRIPTION
    Converts a TOON (Token-Oriented Object Notation) file back to JSON format.
.PARAMETER InputPath
    The path to the TOON file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-ToonToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-ToonToJson @PSBoundParameters
}
Set-Alias -Name toon-to-json -Value ConvertFrom-ToonToJson -ErrorAction SilentlyContinue

# Convert TOON to YAML
<#
.SYNOPSIS
    Converts TOON file to YAML format.
.DESCRIPTION
    Converts a TOON (Token-Oriented Object Notation) file to YAML format.
.PARAMETER InputPath
    The path to the TOON file.
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
#>
function ConvertFrom-ToonToYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-ToonToYaml @PSBoundParameters
}
Set-Alias -Name toon-to-yaml -Value ConvertFrom-ToonToYaml -ErrorAction SilentlyContinue

# Convert YAML to TOON
<#
.SYNOPSIS
    Converts YAML file to TOON format.
.DESCRIPTION
    Converts a YAML file to TOON (Token-Oriented Object Notation) format.
.PARAMETER InputPath
    The path to the YAML file.
.PARAMETER OutputPath
    The path for the output TOON file. If not specified, uses input path with .toon extension.
#>
function ConvertTo-ToonFromYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ToonFromYaml @PSBoundParameters
}
Set-Alias -Name yaml-to-toon -Value ConvertTo-ToonFromYaml -ErrorAction SilentlyContinue

# Convert TOON to CSV
<#
.SYNOPSIS
    Converts TOON file to CSV format.
.DESCRIPTION
    Converts a TOON (Token-Oriented Object Notation) file to CSV format. The TOON must represent an array of objects or a single object.
.PARAMETER InputPath
    The path to the TOON file.
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
#>
function ConvertFrom-ToonToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-ToonToCsv @PSBoundParameters
}
Set-Alias -Name toon-to-csv -Value ConvertFrom-ToonToCsv -ErrorAction SilentlyContinue

# Convert CSV to TOON
<#
.SYNOPSIS
    Converts CSV file to TOON format.
.DESCRIPTION
    Converts a CSV file to TOON (Token-Oriented Object Notation) format.
.PARAMETER InputPath
    The path to the CSV file.
.PARAMETER OutputPath
    The path for the output TOON file. If not specified, uses input path with .toon extension.
#>
function ConvertTo-ToonFromCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ToonFromCsv @PSBoundParameters
}
Set-Alias -Name csv-to-toon -Value ConvertTo-ToonFromCsv -ErrorAction SilentlyContinue

# Convert TOON to XML
<#
.SYNOPSIS
    Converts TOON file to XML format.
.DESCRIPTION
    Converts a TOON (Token-Oriented Object Notation) file to XML format.
.PARAMETER InputPath
    The path to the TOON file.
.PARAMETER OutputPath
    The path for the output XML file. If not specified, uses input path with .xml extension.
#>
function ConvertFrom-ToonToXml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-ToonToXml @PSBoundParameters
}
Set-Alias -Name toon-to-xml -Value ConvertFrom-ToonToXml -ErrorAction SilentlyContinue

# Convert XML to TOON
<#
.SYNOPSIS
    Converts XML file to TOON format.
.DESCRIPTION
    Converts an XML file to TOON (Token-Oriented Object Notation) format.
.PARAMETER InputPath
    The path to the XML file.
.PARAMETER OutputPath
    The path for the output TOON file. If not specified, uses input path with .toon extension.
#>
function ConvertTo-ToonFromXml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-ToonFromXml @PSBoundParameters
}
Set-Alias -Name xml-to-toon -Value ConvertTo-ToonFromXml -ErrorAction SilentlyContinue

