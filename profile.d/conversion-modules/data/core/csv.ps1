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
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.csv.to-json] Starting conversion: $Path"
            }
            
            $convStartTime = Get-Date
            $csvData = Import-Csv -Path $Path
            $rowCount = $csvData.Count
            $json = $csvData | ConvertTo-Json -Depth 10
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.csv.to-json] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.csv.to-json] Rows processed: $rowCount"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $Path) { (Get-Item -LiteralPath $Path).Length } else { 0 }
                $outputLength = $json.Length
                Write-Host "  [conversion.csv.to-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputLength} characters, Rows: $rowCount" -ForegroundColor DarkGray
            }
            
            return $json
        } 
        catch { 
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($Path -and (Test-Path -LiteralPath $Path)) { (Get-Item -LiteralPath $Path).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.csv.to-json' -Context @{
                    input_path = $Path
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert CSV to JSON: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.csv.to-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.csv.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        } 
    } -Force

    # JSON to CSV
    Set-Item -Path Function:Global:_ConvertTo-CsvFromJson -Value { 
        param([string]$Path)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.csv.from-json] Starting conversion: $Path"
            }
            
            $outputPath = $Path.Replace('.json', '.csv')
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.csv.from-json] Output path: $outputPath"
            }
            
            $convStartTime = Get-Date
            $data = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
            $rowCount = 0
            
            if ($data -is [array]) {
                $rowCount = $data.Count
                $data | Export-Csv -NoTypeInformation -Path $outputPath
            } 
            elseif ($data -is [PSCustomObject]) {
                $rowCount = 1
                @($data) | Export-Csv -NoTypeInformation -Path $outputPath
            } 
            else { 
                throw "JSON must be an array of objects or a single object"
            }
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.csv.from-json] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.csv.from-json] Rows created: $rowCount"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $Path) { (Get-Item -LiteralPath $Path).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $outputPath) { (Get-Item -LiteralPath $outputPath).Length } else { 0 }
                Write-Host "  [conversion.csv.from-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Rows: $rowCount" -ForegroundColor DarkGray
            }
        } 
        catch { 
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($Path -and (Test-Path -LiteralPath $Path)) { (Get-Item -LiteralPath $Path).Length } else { 0 }
                $outputPath = $Path.Replace('.json', '.csv')
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.csv.from-json' -Context @{
                    input_path = $Path
                    output_path = $outputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert JSON to CSV: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.csv.from-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.csv.from-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        } 
    } -Force

    # CSV to YAML
    Set-Item -Path Function:Global:_ConvertFrom-CsvToYaml -Value { 
        param([string]$Path)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.csv.to-yaml] Starting conversion: $Path"
            }
            
            $outputPath = $Path -replace '\.csv$', '.yaml'
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.csv.to-yaml] Output path: $outputPath"
            }
            
            $convStartTime = Get-Date
            $csvData = Import-Csv -Path $Path
            $rowCount = $csvData.Count
            $json = $csvData | ConvertTo-Json -Depth 10
            $yaml = $json | & yq eval -P 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "yq command failed with exit code $LASTEXITCODE: $yaml"
            }
            
            $yaml | Out-File -FilePath $outputPath -Encoding UTF8
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.csv.to-yaml] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.csv.to-yaml] Rows processed: $rowCount"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $Path) { (Get-Item -LiteralPath $Path).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $outputPath) { (Get-Item -LiteralPath $outputPath).Length } else { 0 }
                Write-Host "  [conversion.csv.to-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Rows: $rowCount" -ForegroundColor DarkGray
            }
        } 
        catch { 
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($Path -and (Test-Path -LiteralPath $Path)) { (Get-Item -LiteralPath $Path).Length } else { 0 }
                $outputPath = $Path -replace '\.csv$', '.yaml'
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.csv.to-yaml' -Context @{
                    input_path = $Path
                    output_path = $outputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    yq_exit_code = $LASTEXITCODE
                }
            }
            else {
                Write-Error "Failed to convert CSV to YAML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.csv.to-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.csv.to-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
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
    
    # Parse debug level once at function start
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        # Debug is enabled
    }
    
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertFrom-CsvToJson @PSBoundParameters
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            $inputSize = if ($Path -and (Test-Path -LiteralPath $Path)) { (Get-Item -LiteralPath $Path).Length } else { 0 }
            Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.csv.to-json' -Context @{
                input_path = $Path
                input_size_bytes = $inputSize
                error_type = $_.Exception.GetType().FullName
            }
        }
        else {
            Write-Error "Failed to convert CSV to JSON: $($_.Exception.Message)"
        }
        
        # Level 2: Error details
        if ($debugLevel -ge 2) {
            Write-Verbose "[conversion.csv.to-json] Error type: $($_.Exception.GetType().FullName)"
        }
        
        # Level 3: Stack trace
        if ($debugLevel -ge 3) {
            Write-Host "  [conversion.csv.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        }
        
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
    
    # Parse debug level once at function start
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        # Debug is enabled
    }
    
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertTo-CsvFromJson @PSBoundParameters
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            $inputSize = if ($Path -and (Test-Path -LiteralPath $Path)) { (Get-Item -LiteralPath $Path).Length } else { 0 }
            $outputPath = $Path.Replace('.json', '.csv')
            Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.csv.from-json' -Context @{
                input_path = $Path
                output_path = $outputPath
                input_size_bytes = $inputSize
                error_type = $_.Exception.GetType().FullName
            }
        }
        else {
            Write-Error "Failed to convert JSON to CSV: $($_.Exception.Message)"
        }
        
        # Level 2: Error details
        if ($debugLevel -ge 2) {
            Write-Verbose "[conversion.csv.from-json] Error type: $($_.Exception.GetType().FullName)"
        }
        
        # Level 3: Stack trace
        if ($debugLevel -ge 3) {
            Write-Host "  [conversion.csv.from-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        }
        
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
    
    # Parse debug level once at function start
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        # Debug is enabled
    }
    
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertFrom-YamlToCsv @PSBoundParameters
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            $inputSize = if ($Path -and (Test-Path -LiteralPath $Path)) { (Get-Item -LiteralPath $Path).Length } else { 0 }
            $outputPath = $Path -replace '\.ya?ml$', '.csv'
            Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.csv.from-yaml' -Context @{
                input_path = $Path
                output_path = $outputPath
                input_size_bytes = $inputSize
                error_type = $_.Exception.GetType().FullName
                yq_exit_code = $LASTEXITCODE
            }
        }
        else {
            Write-Error "Failed to convert YAML to CSV: $($_.Exception.Message)"
        }
        
        # Level 2: Error details
        if ($debugLevel -ge 2) {
            Write-Verbose "[conversion.csv.from-yaml] Error type: $($_.Exception.GetType().FullName)"
        }
        
        # Level 3: Stack trace
        if ($debugLevel -ge 3) {
            Write-Host "  [conversion.csv.from-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        }
        
        throw
    }
}
Set-Alias -Name yaml-to-csv -Value ConvertFrom-YamlToCsv -ErrorAction SilentlyContinue

