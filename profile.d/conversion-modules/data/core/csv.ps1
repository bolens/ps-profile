# ===============================================
# CSV format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes CSV format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for CSV format conversions.
    Supports bidirectional conversions between CSV and JSON, and CSV and YAML.
    This function is called automatically by Initialize-FileConversion-CoreBasic.
.NOTES
    This is an internal initialization function and should not be called directly.
    CSV to YAML conversion requires yq command-line tool.
#>
function Initialize-FileConversion-CoreBasicCsv {
    # CSV to JSON
    Set-Item -Path Function:Global:_ConvertFrom-CsvToJson -Value { 
        param([string]$Path) 
        try { 
            Import-Csv -Path $Path | ConvertTo-Json -Depth 10 
        } 
        catch { 
            Write-Error "Failed to convert CSV to JSON: $_" 
        } 
    } -Force

    # JSON to CSV
    Set-Item -Path Function:Global:_ConvertTo-CsvFromJson -Value { 
        param([string]$Path) 
        try { 
            $data = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
            if ($data -is [array]) { 
                $data | Export-Csv -NoTypeInformation -Path $Path.Replace('.json', '.csv') 
            } 
            elseif ($data -is [PSCustomObject]) { 
                @($data) | Export-Csv -NoTypeInformation -Path $Path.Replace('.json', '.csv') 
            } 
            else { 
                Write-Error "JSON must be an array of objects or a single object" 
            } 
        } 
        catch { 
            Write-Error "Failed to convert JSON to CSV: $_" 
        } 
    } -Force

    # CSV to YAML
    Set-Item -Path Function:Global:_ConvertFrom-CsvToYaml -Value { 
        param([string]$Path) 
        try { 
            Import-Csv -Path $Path | ConvertTo-Json -Depth 10 | & yq eval -P | Out-File -FilePath ($Path -replace '\.csv$', '.yaml') -Encoding UTF8 
        } 
        catch { 
            Write-Error "Failed to convert CSV to YAML: $_" 
        } 
    } -Force

    # YAML to CSV
    Set-Item -Path Function:Global:_ConvertFrom-YamlToCsv -Value {
        param([string]$Path)
        try {
            $json = & yq eval -o=json $Path 2>$null
            if ($LASTEXITCODE -ne 0 -or -not $json -or $json -eq 'null') {
                return
            }
            $data = $json | ConvertFrom-Json
            if (-not $data) {
                return
            }
            $data | Export-Csv -NoTypeInformation -Path ($Path -replace '\.ya?ml$', '.csv')
        }
        catch {
            Write-Error "Failed to convert YAML to CSV: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert CSV to JSON
<#
.SYNOPSIS
    Converts CSV file to JSON format.
.DESCRIPTION
    Reads a CSV file and outputs its contents as JSON.
.PARAMETER Path
    The path to the CSV file to convert.
#>
function ConvertFrom-CsvToJson {
    param([string]$Path)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertFrom-CsvToJson @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert CSV to JSON: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name csv-to-json -Value ConvertFrom-CsvToJson -ErrorAction SilentlyContinue

# Convert JSON to CSV
<#
.SYNOPSIS
    Converts JSON file to CSV format.
.DESCRIPTION
    Parses a JSON file containing an array of objects and converts it to CSV.
.PARAMETER Path
    The path to the JSON file to convert.
#>
function ConvertTo-CsvFromJson {
    param([string]$Path)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertTo-CsvFromJson @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert JSON to CSV: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name json-to-csv -Value ConvertTo-CsvFromJson -ErrorAction SilentlyContinue

# Convert CSV to YAML
<#
.SYNOPSIS
    Converts CSV file to YAML format.
.DESCRIPTION
    Reads a CSV file and outputs its contents as YAML.
.PARAMETER Path
    The path to the CSV file to convert.
#>
function ConvertFrom-CsvToYaml {
    param([string]$Path)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertFrom-CsvToYaml @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert CSV to YAML: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name csv-to-yaml -Value ConvertFrom-CsvToYaml -ErrorAction SilentlyContinue

# Convert YAML to CSV
<#
.SYNOPSIS
    Converts YAML file to CSV format.
.DESCRIPTION
    Reads a YAML file and outputs its contents as CSV.
.PARAMETER Path
    The path to the YAML file to convert.
#>
function ConvertFrom-YamlToCsv {
    param([string]$Path)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertFrom-YamlToCsv @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert YAML to CSV: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name yaml-to-csv -Value ConvertFrom-YamlToCsv -ErrorAction SilentlyContinue

