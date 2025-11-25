# ===============================================
# Basic text format conversion utilities
# JSON, YAML, CSV, XML, Base64
# ===============================================

<#
.SYNOPSIS
    Initializes basic text format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for basic text formats: JSON, YAML, CSV, XML, and Base64.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-CoreBasic {
    # Ensure NodeJs module is imported (use repo root from bootstrap if available)
    if (-not (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Variable -Name 'RepoRoot' -Scope Script -ErrorAction SilentlyContinue) {
            $script:RepoRoot
        }
        elseif (Get-Variable -Name 'BootstrapRoot' -Scope Script -ErrorAction SilentlyContinue) {
            Split-Path -Parent $script:BootstrapRoot
        }
        else {
            Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        }
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'NodeJs.psm1'
        if (Test-Path $nodeJsModulePath) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
        }
    }
    # JSON pretty-print
    Set-Item -Path Function:Global:_Format-Json -Value {
        param(
            [Parameter(ValueFromPipeline = $true)]
            $InputObject,
            [Parameter(ValueFromRemainingArguments = $true)]
            $fileArgs
        )
        process {
            $rawInput = $null
            try {
                if ($fileArgs) {
                    $rawInput = Get-Content -Raw -LiteralPath @fileArgs
                    $rawInput | ConvertFrom-Json -ErrorAction Stop | ConvertTo-Json -Depth 10
                }
                elseif ($PSBoundParameters.ContainsKey('InputObject') -and $null -ne $InputObject) {
                    $rawInput = $InputObject
                    $rawInput | ConvertFrom-Json -ErrorAction Stop | ConvertTo-Json -Depth 10
                }
                else {
                    $rawInput = $input | Out-String
                    if ([string]::IsNullOrWhiteSpace($rawInput)) {
                        return
                    }
                    $rawInput | ConvertFrom-Json -ErrorAction Stop | ConvertTo-Json -Depth 10
                }
            }
            catch {
                # Only show warning when not running in Pester tests
                if (-not (Get-Module -Name Pester -ErrorAction SilentlyContinue)) {
                    Write-Warning "Failed to pretty-print JSON: $($_.Exception.Message)"
                }
                if ($null -ne $rawInput) {
                    Write-Output $rawInput
                }
            }
        }
    } -Force

    # YAML to JSON
    Set-Item -Path Function:Global:_ConvertFrom-Yaml -Value {
        param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
        try {
            if (-not $fileArgs -or $fileArgs.Count -eq 0) {
                throw "File path parameter is required"
            }
            
            $resolvedPath = Resolve-Path @fileArgs -ErrorAction Stop | Select-Object -ExpandProperty Path
            if (-not (Test-Path $resolvedPath)) {
                throw "Input file not found: $resolvedPath"
            }
            
            $yqCommand = Get-Command yq -ErrorAction SilentlyContinue
            if (-not $yqCommand) {
                $errorMessage = "yq command not found. Please install yq to use this conversion function."
                $errorMessage += "`nSuggestion: Install yq from https://github.com/mikefarah/yq or use a package manager (scoop, choco, winget)"
                throw $errorMessage
            }
            
            # Validate yq is executable
            try {
                $yqVersion = & yq --version 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "yq command exists but failed to execute (exit code: $LASTEXITCODE)"
                }
            }
            catch {
                throw "yq command found at '$($yqCommand.Source)' but is not executable: $($_.Exception.Message)"
            }
            
            # Execute with error capture
            $errorOutput = & yq eval -o=json '.' $resolvedPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                return $errorOutput
            }
            
            # Build error message
            if (-not $errorOutput) {
                Write-Error "yq command failed with exit code $exitCode : Unknown error (no output from yq)" -ErrorAction SilentlyContinue
                return $null
            }
            
            # Filter out warnings
            $filteredOutput = $errorOutput | Where-Object { $_ -notmatch '^WARNING:' }
            $errorMessage = if ($filteredOutput) {
                $filteredOutput -join "`n"
            }
            else {
                $errorOutput -join "`n"
            }
            Write-Error "yq command failed with exit code $exitCode : $errorMessage" -ErrorAction SilentlyContinue
            return $null
        }
        catch {
            Write-Error "Failed to convert YAML to JSON: $($_.Exception.Message)" -ErrorAction SilentlyContinue
            return $null
        }
    } -Force

    # JSON to YAML
    Set-Item -Path Function:Global:_ConvertTo-Yaml -Value {
        param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
        try {
            if (-not $fileArgs -or $fileArgs.Count -eq 0) {
                throw "File path parameter is required"
            }
            
            $resolvedPath = Resolve-Path @fileArgs -ErrorAction Stop | Select-Object -ExpandProperty Path
            if (-not (Test-Path $resolvedPath)) {
                throw "Input file not found: $resolvedPath"
            }
            
            $yqCommand = Get-Command yq -ErrorAction SilentlyContinue
            if (-not $yqCommand) {
                $errorMessage = "yq command not found. Please install yq to use this conversion function."
                $errorMessage += "`nSuggestion: Install yq from https://github.com/mikefarah/yq or use a package manager (scoop, choco, winget)"
                throw $errorMessage
            }
            
            # Validate yq is executable (reuse validation from above if already checked)
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
            
            # Execute with error capture
            $errorOutput = & yq eval -p json -o yaml '.' $resolvedPath 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                return $errorOutput -join "`n"
            }
            
            # Build error message
            if (-not $errorOutput) {
                Write-Error "yq command failed with exit code $exitCode : Unknown error (no output from yq)" -ErrorAction SilentlyContinue
                return $null
            }
            
            # Filter out warnings
            $filteredOutput = $errorOutput | Where-Object { $_ -notmatch '^WARNING:' }
            $errorMessage = if ($filteredOutput) {
                $filteredOutput -join "`n"
            }
            else {
                $errorOutput -join "`n"
            }
            Write-Error "yq command failed with exit code $exitCode : $errorMessage" -ErrorAction SilentlyContinue
            return $null
        }
        catch {
            Write-Error "Failed to convert JSON to YAML: $($_.Exception.Message)" -ErrorAction SilentlyContinue
            return $null
        }
    } -Force

    # Base64 encode
    Set-Item -Path Function:Global:_ConvertTo-Base64 -Value {
        param([Parameter(ValueFromPipeline = $true)] $InputObject)
        process {
            if ($InputObject -is [byte[]]) {
                return [Convert]::ToBase64String($InputObject)
            }
            $text = [string]$InputObject
            $bytes = [Text.Encoding]::UTF8.GetBytes($text)
            return [Convert]::ToBase64String($bytes)
        }
    } -Force

    # Base64 decode
    Set-Item -Path Function:Global:_ConvertFrom-Base64 -Value {
        param([Parameter(ValueFromPipeline = $true)] $InputObject)
        process {
            $s = [string]$InputObject -replace '\s+', ''
            try {
                $bytes = [Convert]::FromBase64String($s)
                return [Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                Write-Error "Invalid base64 input: $_"
            }
        }
    } -Force

    # CSV to JSON
    Set-Item -Path Function:Global:_ConvertFrom-CsvToJson -Value { param([string]$Path) try { Import-Csv -Path $Path | ConvertTo-Json -Depth 10 } catch { Write-Error "Failed to convert CSV to JSON: $_" } } -Force

    # JSON to CSV
    Set-Item -Path Function:Global:_ConvertTo-CsvFromJson -Value { param([string]$Path) try { $data = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json; if ($data -is [array]) { $data | Export-Csv -NoTypeInformation -Path $Path.Replace('.json', '.csv') } elseif ($data -is [PSCustomObject]) { @($data) | Export-Csv -NoTypeInformation -Path $Path.Replace('.json', '.csv') } else { Write-Error "JSON must be an array of objects or a single object" } } catch { Write-Error "Failed to convert JSON to CSV: $_" } } -Force

    # XML to JSON
    Set-Item -Path Function:Global:_ConvertFrom-XmlToJson -Value { param([string]$Path) try { $xml = [xml](Get-Content -LiteralPath $Path -Raw); $result = @{}; $result[$xml.DocumentElement.Name] = Convert-XmlToJsonObject $xml.DocumentElement; [PSCustomObject]$result | ConvertTo-Json -Depth 100 } catch { Write-Error "Failed to parse XML: $_" } } -Force

    # CSV to YAML
    Set-Item -Path Function:Global:_ConvertFrom-CsvToYaml -Value { param([string]$Path) try { Import-Csv -Path $Path | ConvertTo-Json -Depth 10 | & yq eval -P | Out-File -FilePath ($Path -replace '\.csv$', '.yaml') -Encoding UTF8 } catch { Write-Error "Failed to convert CSV to YAML: $_" } } -Force

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
# Pretty-print JSON
<#
.SYNOPSIS
    Pretty-prints JSON data.
.DESCRIPTION
    Formats JSON data with proper indentation and structure.
#>
function Format-Json {
    param([Parameter(ValueFromPipeline = $true)] $InputObject, [Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        & "Global:_Format-Json" @PSBoundParameters
    }
    catch {
        Write-Error "Failed to pretty-print JSON: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name json-pretty -Value Format-Json -ErrorAction SilentlyContinue

# Convert YAML to JSON
<#
.SYNOPSIS
    Converts YAML to JSON format.
.DESCRIPTION
    Transforms YAML input to JSON output using yq.
#>
function ConvertFrom-Yaml {
    param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Yaml @PSBoundParameters
}
Set-Alias -Name yaml-to-json -Value ConvertFrom-Yaml -ErrorAction SilentlyContinue

# Convert JSON to YAML
<#
.SYNOPSIS
    Converts JSON to YAML format.
.DESCRIPTION
    Transforms JSON input to YAML output using yq.
#>
function ConvertTo-Yaml {
    param([Parameter(ValueFromRemainingArguments = $true)] $fileArgs)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertTo-Yaml @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert JSON to YAML: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name json-to-yaml -Value ConvertTo-Yaml -ErrorAction SilentlyContinue

# Encode to base64
<#
.SYNOPSIS
    Encodes input to base64 format.
.DESCRIPTION
    Converts file contents or string input to base64 encoded string.
.PARAMETER InputObject
    The file path or string to encode.
#>
function ConvertTo-Base64 {
    param([Parameter(ValueFromPipeline = $true)] $InputObject)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        & "Global:_ConvertTo-Base64" @PSBoundParameters
    }
    catch {
        Write-Error "Failed to encode to base64: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name to-base64 -Value ConvertTo-Base64 -ErrorAction SilentlyContinue

# Decode from base64
<#
.SYNOPSIS
    Decodes base64 input to text.
.DESCRIPTION
    Converts base64 encoded string back to readable text.
.PARAMETER InputObject
    The base64 string to decode.
#>
function ConvertFrom-Base64 {
    param([Parameter(ValueFromPipeline = $true)] $InputObject)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        & "Global:_ConvertFrom-Base64" @PSBoundParameters
    }
    catch {
        Write-Error "Failed to decode from base64: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name from-base64 -Value ConvertFrom-Base64 -ErrorAction SilentlyContinue

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

# Convert JSON5 to JSON
<#
.SYNOPSIS
    Converts JSON5 file to JSON format.
.DESCRIPTION
    Converts a JSON5 file (JSON with comments and trailing commas) to standard JSON format.
    Requires Node.js and the json5 package to be installed.
.PARAMETER InputPath
    The path to the JSON5 file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-Json5ToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertFrom-Json5ToJson @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert JSON5 to JSON: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name json5-to-json -Value ConvertFrom-Json5ToJson -ErrorAction SilentlyContinue

# Convert JSON to JSON5
<#
.SYNOPSIS
    Converts JSON file to JSON5 format.
.DESCRIPTION
    Converts a JSON file to JSON5 format (JSON with comments and trailing commas support).
    Requires Node.js and the json5 package to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output JSON5 file. If not specified, uses input path with .json5 extension.
#>
function ConvertTo-Json5FromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        _ConvertTo-Json5FromJson @PSBoundParameters
    }
    catch {
        Write-Error "Failed to convert JSON to JSON5: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name json-to-json5 -Value ConvertTo-Json5FromJson -ErrorAction SilentlyContinue