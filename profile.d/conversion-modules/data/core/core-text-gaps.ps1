# ===============================================
# Text format gap conversion utilities
# Direct conversions: XML↔YAML, JSONL↔CSV, JSONL↔YAML
# ===============================================

<#
.SYNOPSIS
    Initializes text format gap conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for direct text format conversions that fill gaps
    in the conversion matrix: XML↔YAML, JSONL↔CSV, JSONL↔YAML.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires yq for XML↔YAML conversions.
#>
function Initialize-FileConversion-CoreTextGaps {
    # XML to YAML (direct conversion using yq)
    Set-Item -Path Function:Global:_ConvertFrom-XmlToYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.xml$', '.yaml' }
            $yqCommand = Get-Command yq -ErrorAction SilentlyContinue
            if (-not $yqCommand) {
                $errorMessage = "yq is not available. Install yq to use XML to YAML conversions."
                $errorMessage += "`nSuggestion: Install yq from https://github.com/mikefarah/yq or use a package manager (scoop, choco, winget)"
                throw $errorMessage
            }
            
            # Validate yq is executable
            if (-not $script:YqValidated) {
                try {
                    $yqVersion = & yq --version 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "yq command exists but failed to execute (exit code: $LASTEXITCODE)"
                    }
                    $script:YqValidated = $true
                }
                catch {
                    throw "yq command found at '$($yqCommand.Source)' but is not executable: $($_.Exception.Message)"
                }
            }
            
            $result = & yq eval -p xml -o yaml '.' $InputPath 2>&1
            if ($LASTEXITCODE -eq 0) {
                try {
                    $result | Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop
                }
                catch {
                    throw "Failed to write YAML file '$OutputPath': $($_.Exception.Message)"
                }
                return
            }
            
            # Build error message
            if (-not $result) {
                throw "yq command failed with exit code $LASTEXITCODE : Unknown error (no output from yq)"
            }
            
            # Filter out warnings
            $filteredOutput = $result | Where-Object { $_ -notmatch '^WARNING:' }
            $errorMessage = if ($filteredOutput) {
                $filteredOutput -join "`n"
            }
            else {
                $result -join "`n"
            }
            throw "yq command failed with exit code $LASTEXITCODE : $errorMessage"
        }
        catch {
            Write-Error "Failed to convert XML to YAML: $_"
            throw
        }
    } -Force

    # YAML to XML (direct conversion using yq)
    Set-Item -Path Function:Global:_ConvertTo-XmlFromYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.yaml$', '.xml' }
            $yqCommand = Get-Command yq -ErrorAction SilentlyContinue
            if (-not $yqCommand) {
                $errorMessage = "yq is not available. Install yq to use YAML to XML conversions."
                $errorMessage += "`nSuggestion: Install yq from https://github.com/mikefarah/yq or use a package manager (scoop, choco, winget)"
                throw $errorMessage
            }
            
            # Validate yq is executable (reuse validation if already checked)
            if (-not $script:YqValidated) {
                try {
                    $yqVersion = & yq --version 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "yq command exists but failed to execute (exit code: $LASTEXITCODE)"
                    }
                    $script:YqValidated = $true
                }
                catch {
                    throw "yq command found at '$($yqCommand.Source)' but is not executable: $($_.Exception.Message)"
                }
            }
            
            $result = & yq eval -p yaml -o xml '.' $InputPath 2>&1
            if ($LASTEXITCODE -eq 0) {
                try {
                    $result | Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop
                }
                catch {
                    throw "Failed to write XML file '$OutputPath': $($_.Exception.Message)"
                }
                return
            }
            
            # Build error message
            if (-not $result) {
                throw "yq command failed with exit code $LASTEXITCODE : Unknown error (no output from yq)"
            }
            
            # Filter out warnings
            $filteredOutput = $result | Where-Object { $_ -notmatch '^WARNING:' }
            $errorMessage = if ($filteredOutput) {
                $filteredOutput -join "`n"
            }
            else {
                $result -join "`n"
            }
            throw "yq command failed with exit code $LASTEXITCODE : $errorMessage"
        }
        catch {
            Write-Error "Failed to convert YAML to XML: $_"
        }
    } -Force

    # JSONL to CSV (line-by-line conversion)
    Set-Item -Path Function:Global:_ConvertFrom-JsonLToCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not (Test-Path $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.jsonl$', '.csv' }
            
            $lines = Get-Content -LiteralPath $InputPath -ErrorAction Stop
            $objects = @()
            $lineNumber = 0
            $errors = @()
            
            foreach ($line in $lines) {
                $lineNumber++
                if (-not [string]::IsNullOrWhiteSpace($line)) {
                    try {
                        $parsed = $line | ConvertFrom-Json -ErrorAction Stop
                        if ($null -ne $parsed) {
                            $objects += $parsed
                        }
                    }
                    catch {
                        $errors += "Line $lineNumber : $($_.Exception.Message)"
                    }
                }
            }
            
            if ($errors.Count -gt 0) {
                Write-Warning "Failed to parse $($errors.Count) line(s) in JSONL file. Errors: $($errors -join '; ')"
            }
            
            if ($objects.Count -gt 0) {
                try {
                    $objects | Export-Csv -Path $OutputPath -NoTypeInformation -ErrorAction Stop
                }
                catch {
                    throw "Failed to write CSV file '$OutputPath': $($_.Exception.Message)"
                }
                return
            }
            
            # Handle empty objects case
            if ($errors.Count -eq 0) {
                # Empty file is valid, just create empty CSV
                Set-Content -LiteralPath $OutputPath -Value '' -Encoding UTF8 -ErrorAction Stop
                return
            }
            
            throw "No valid JSON objects found in JSONL file. All lines failed to parse."
        }
        catch {
            Write-Error "Failed to convert JSONL to CSV: $($_.Exception.Message)"
            throw
        }
    } -Force

    # CSV to JSONL (line-by-line conversion)
    Set-Item -Path Function:Global:_ConvertTo-JsonLFromCsv -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not (Test-Path $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.csv$', '.jsonl' }
            
            try {
                $csvData = Import-Csv -Path $InputPath -ErrorAction Stop
            }
            catch {
                throw "Failed to read CSV file '$InputPath': $($_.Exception.Message)"
            }
            
            $output = @()
            foreach ($row in $csvData) {
                try {
                    $jsonLine = $row | ConvertTo-Json -Compress -Depth 100 -ErrorAction Stop
                    if ($jsonLine) {
                        $output += $jsonLine
                    }
                }
                catch {
                    Write-Warning "Failed to convert CSV row to JSON: $($_.Exception.Message). Skipping row."
                }
            }
            
            if ($output.Count -gt 0) {
                try {
                    $output | Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop
                }
                catch {
                    throw "Failed to write JSONL file '$OutputPath': $($_.Exception.Message)"
                }
            }
            else {
                throw "No valid data to convert. CSV file may be empty or all rows failed to convert."
            }
        }
        catch {
            Write-Error "Failed to convert CSV to JSONL: $($_.Exception.Message)"
            throw
        }
    } -Force

    # JSONL to YAML
    Set-Item -Path Function:Global:_ConvertFrom-JsonLToYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.jsonl$', '.yaml' }
            # Convert JSONL to JSON first, then JSON to YAML
            $tempJson = Join-Path $env:TEMP "jsonl-to-yaml-$(Get-Random).json"
            try {
                _ConvertFrom-JsonLToJson -InputPath $InputPath -OutputPath $tempJson
                # Ensure yq is validated
                if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                    throw "yq is not available. Install yq to use JSONL to YAML conversions."
                }
                
                $yamlResult = & yq eval -p json -o yaml '.' $tempJson 2>&1
                if ($LASTEXITCODE -eq 0) {
                    try {
                        $yamlResult | Set-Content -LiteralPath $OutputPath -Encoding UTF8 -ErrorAction Stop
                    }
                    catch {
                        throw "Failed to write YAML file '$OutputPath': $($_.Exception.Message)"
                    }
                    return
                }
                
                # Build error message
                if (-not $yamlResult) {
                    throw "yq command failed with exit code $LASTEXITCODE : Unknown error (no output from yq)"
                }
                
                # Filter out warnings
                $filteredOutput = $yamlResult | Where-Object { $_ -notmatch '^WARNING:' }
                $errorMessage = if ($filteredOutput) {
                    $filteredOutput -join "`n"
                }
                else {
                    $yamlResult -join "`n"
                }
                throw "yq command failed with exit code $LASTEXITCODE : $errorMessage"
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert JSONL to YAML: $($_.Exception.Message)"
            throw
        }
    } -Force

    # YAML to JSONL
    Set-Item -Path Function:Global:_ConvertTo-JsonLFromYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.yaml$', '.jsonl' }
            # Convert YAML to JSON first, then JSON to JSONL
            $tempJson = Join-Path $env:TEMP "yaml-to-jsonl-$(Get-Random).json"
            try {
                $jsonResult = & yq eval -o=json '.' $InputPath 2>&1
                if ($LASTEXITCODE -ne 0) {
                    $errorMessage = if ($jsonResult) {
                        $jsonResult -join "`n"
                    }
                    else {
                        "Unknown error"
                    }
                    throw "yq command failed with exit code $LASTEXITCODE : $errorMessage"
                }
                try {
                    $jsonResult | Set-Content -LiteralPath $tempJson -Encoding UTF8 -ErrorAction Stop
                }
                catch {
                    throw "Failed to write temporary JSON file '$tempJson': $($_.Exception.Message)"
                }
                _ConvertTo-JsonLFromJson -InputPath $tempJson -OutputPath $OutputPath
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert YAML to JSONL: $($_.Exception.Message)"
            throw
        }
    } -Force
}

function ConvertTo-XmlFromYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertTo-XmlFromYaml @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert YAML to XML: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name yaml-to-xml -Value ConvertTo-XmlFromYaml -ErrorAction SilentlyContinue

# Convert JSONL to CSV
<#
.SYNOPSIS
    Converts JSONL file to CSV format.
.DESCRIPTION
    Converts a JSONL (JSON Lines) file to CSV format by parsing each line as a JSON object
    and combining them into a CSV file. Each line in the JSONL file becomes a row in the CSV.
.PARAMETER InputPath
    The path to the JSONL file.
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
#>
function ConvertFrom-JsonLToCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertFrom-JsonLToCsv @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert JSONL to CSV: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name jsonl-to-csv -Value ConvertFrom-JsonLToCsv -ErrorAction SilentlyContinue

# Convert CSV to JSONL
<#
.SYNOPSIS
    Converts CSV file to JSONL format.
.DESCRIPTION
    Converts a CSV file to JSONL (JSON Lines) format by converting each row to a JSON object
    and writing it as a separate line. Each row in the CSV becomes a line in the JSONL file.
.PARAMETER InputPath
    The path to the CSV file.
.PARAMETER OutputPath
    The path for the output JSONL file. If not specified, uses input path with .jsonl extension.
#>
function ConvertTo-JsonLFromCsv {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertTo-JsonLFromCsv @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert CSV to JSONL: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name csv-to-jsonl -Value ConvertTo-JsonLFromCsv -ErrorAction SilentlyContinue

# Convert JSONL to YAML
<#
.SYNOPSIS
    Converts JSONL file to YAML format.
.DESCRIPTION
    Converts a JSONL (JSON Lines) file to YAML format by first combining all lines into a JSON array,
    then converting to YAML.
.PARAMETER InputPath
    The path to the JSONL file.
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
#>
function ConvertFrom-JsonLToYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertFrom-JsonLToYaml @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert JSONL to YAML: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name jsonl-to-yaml -Value ConvertFrom-JsonLToYaml -ErrorAction SilentlyContinue

# Convert YAML to JSONL
<#
.SYNOPSIS
    Converts YAML file to JSONL format.
.DESCRIPTION
    Converts a YAML file to JSONL (JSON Lines) format by first converting to JSON,
    then splitting into individual lines if the data is an array.
.PARAMETER InputPath
    The path to the YAML file.
.PARAMETER OutputPath
    The path for the output JSONL file. If not specified, uses input path with .jsonl extension.
#>
function ConvertTo-JsonLFromYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertTo-JsonLFromYaml @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert YAML to JSONL: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name yaml-to-jsonl -Value ConvertTo-JsonLFromYaml -ErrorAction SilentlyContinue

