# ===============================================
# INI (Initialization) format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes INI format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for INI (Initialization) format.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    INI format supports sections, key-value pairs, and comments.
    
    Internal Dependencies:
    - helpers-xml.ps1: Provides Convert-JsonToXml for INI to XML conversions
#>
function Initialize-FileConversion-Ini {
    # INI to JSON
    Set-Item -Path Function:Global:_ConvertFrom-IniToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.ini.to-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ini$', '.json'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.to-json] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $iniContent = Get-Content -LiteralPath $InputPath -Raw
            $result = @{}
            $currentSection = $null
            
            $lines = $iniContent -split "`r?`n"
            foreach ($line in $lines) {
                $line = $line.Trim()
                
                # Skip empty lines and comments
                if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith(';') -or $line.StartsWith('#')) {
                    continue
                }
                
                # Check for section header [section]
                if ($line -match '^\[(.+)\]$') {
                    $currentSection = $matches[1]
                    if (-not $result.ContainsKey($currentSection)) {
                        $result[$currentSection] = @{}
                    }
                    continue
                }
                
                # Check for key=value pair
                if ($line -match '^([^=]+)=(.*)$') {
                    $key = $matches[1].Trim()
                    $value = $matches[2].Trim()
                    
                    # Remove quotes if present
                    if ($value.StartsWith('"') -and $value.EndsWith('"')) {
                        $value = $value.Substring(1, $value.Length - 2)
                    }
                    elseif ($value.StartsWith("'") -and $value.EndsWith("'")) {
                        $value = $value.Substring(1, $value.Length - 2)
                    }
                    
                    if ($null -eq $currentSection) {
                        # Global section
                        if (-not $result.ContainsKey('')) {
                            $result[''] = @{}
                        }
                        $result[''][$key] = $value
                    }
                    else {
                        $result[$currentSection][$key] = $value
                    }
                }
            }
            
            # Convert to JSON
            $jsonObj = [PSCustomObject]$result
            $json = $jsonObj | ConvertTo-Json -Depth 100
            Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.to-json] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.ini.to-json] Sections found: $($result.Keys.Count)"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path $InputPath) { (Get-Item $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path $OutputPath) { (Get-Item $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.ini.to-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Sections: $($result.Keys.Count)" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.ini.to-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                }
            }
            else {
                Write-Error "Failed to convert INI to JSON: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.to-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.ini.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
        }
    } -Force

    # JSON to INI
    Set-Item -Path Function:Global:_ConvertTo-IniFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.ini.from-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.ini'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.from-json] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            $iniLines = @()
            $sectionCount = 0
            $keyCount = 0
            
            # Process each section
            $jsonObj.PSObject.Properties | ForEach-Object {
                $sectionName = $_.Name
                $sectionData = $_.Value
                
                # Write section header
                if ([string]::IsNullOrWhiteSpace($sectionName)) {
                    # Global section - no header
                }
                else {
                    $iniLines += "[$sectionName]"
                    $sectionCount++
                }
                
                # Write key-value pairs
                if ($sectionData -is [PSCustomObject] -or $sectionData -is [Hashtable]) {
                    $sectionData.PSObject.Properties | ForEach-Object {
                        $key = $_.Name
                        $value = $_.Value
                        
                        # Escape value if it contains special characters
                        if ($value -match '[;=#\[\]]') {
                            $value = """$value"""
                        }
                        
                        $iniLines += "$key=$value"
                        $keyCount++
                    }
                }
                
                # Add blank line between sections
                $iniLines += ''
            }
            
            $iniContent = $iniLines -join "`r`n"
            Set-Content -LiteralPath $OutputPath -Value $iniContent -Encoding UTF8
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.from-json] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.ini.from-json] Sections: $sectionCount, Keys: $keyCount"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.ini.from-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Sections: $sectionCount, Keys: $keyCount" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.ini.from-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert JSON to INI: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.from-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.ini.from-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # INI to YAML
    Set-Item -Path Function:Global:_ConvertFrom-IniToYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.ini.to-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ini$', '.yaml'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.to-yaml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert INI to JSON first, then JSON to YAML
            $tempJson = [System.IO.Path]::GetTempFileName() + '.json'
            try {
                _ConvertFrom-IniToJson -InputPath $InputPath -OutputPath $tempJson
                $json = Get-Content -LiteralPath $tempJson -Raw
                $yaml = & yq eval -P '.' $tempJson 2>$null
                if ($LASTEXITCODE -eq 0 -and $yaml) {
                    Set-Content -LiteralPath $OutputPath -Value $yaml -Encoding UTF8
                }
                else {
                    throw "yq command failed"
                }
            }
            finally {
                if ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and (Test-Path -LiteralPath $tempJson)) {
                    Remove-Item $tempJson -Force -ErrorAction SilentlyContinue
                }
            }
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.to-yaml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.ini.to-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.ini.to-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    yq_exit_code = $LASTEXITCODE
                }
            }
            else {
                Write-Error "Failed to convert INI to YAML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.to-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.ini.to-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # YAML to INI
    Set-Item -Path Function:Global:_ConvertTo-IniFromYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.ini.from-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ya?ml$', '.ini'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.from-yaml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert YAML to JSON first, then JSON to INI
            $tempJson = [System.IO.Path]::GetTempFileName() + '.json'
            try {
                $json = & yq eval -o=json $InputPath 2>$null
                if ($LASTEXITCODE -eq 0 -and $json) {
                    $json | Set-Content -LiteralPath $tempJson -Encoding UTF8
                    _ConvertTo-IniFromJson -InputPath $tempJson -OutputPath $OutputPath
                }
                else {
                    throw "yq command failed"
                }
            }
            finally {
                if ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and (Test-Path -LiteralPath $tempJson)) {
                    Remove-Item $tempJson -Force -ErrorAction SilentlyContinue
                }
            }
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.from-yaml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.ini.from-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.ini.from-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    yq_exit_code = $LASTEXITCODE
                }
            }
            else {
                Write-Error "Failed to convert YAML to INI: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.from-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.ini.from-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # INI to XML
    Set-Item -Path Function:Global:_ConvertFrom-IniToXml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.ini.to-xml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ini$', '.xml'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.to-xml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert INI to JSON first, then JSON to XML
            $tempJson = [System.IO.Path]::GetTempFileName() + '.json'
            try {
                _ConvertFrom-IniToJson -InputPath $InputPath -OutputPath $tempJson
                $jsonObj = Get-Content -LiteralPath $tempJson -Raw | ConvertFrom-Json
                $xml = Convert-JsonToXml -JsonObject $jsonObj
                $xml.Save($OutputPath)
            }
            finally {
                if ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and (Test-Path -LiteralPath $tempJson)) {
                    Remove-Item $tempJson -Force -ErrorAction SilentlyContinue
                }
            }
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.to-xml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.ini.to-xml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.ini.to-xml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert INI to XML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.to-xml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.ini.to-xml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # XML to INI
    Set-Item -Path Function:Global:_ConvertTo-IniFromXml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.ini.from-xml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.xml$', '.ini'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.from-xml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert XML to JSON first, then JSON to INI
            $tempJson = [System.IO.Path]::GetTempFileName() + '.json'
            try {
                $xml = [xml](Get-Content -LiteralPath $InputPath -Raw)
                $result = @{}
                $result[$xml.DocumentElement.Name] = Convert-XmlToJsonObject $xml.DocumentElement
                $jsonObj = [PSCustomObject]$result
                $json = $jsonObj | ConvertTo-Json -Depth 100
                $json | Set-Content -LiteralPath $tempJson -Encoding UTF8
                _ConvertTo-IniFromJson -InputPath $tempJson -OutputPath $OutputPath
            }
            finally {
                if ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and (Test-Path -LiteralPath $tempJson)) {
                    Remove-Item $tempJson -Force -ErrorAction SilentlyContinue
                }
            }
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.from-xml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.ini.from-xml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.ini.from-xml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert XML to INI: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.from-xml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.ini.from-xml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # INI to TOML
    Set-Item -Path Function:Global:_ConvertFrom-IniToToml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.ini.to-toml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ini$', '.toml'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.to-toml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert INI to JSON first, then JSON to TOML
            $tempJson = [System.IO.Path]::GetTempFileName() + '.json'
            try {
                _ConvertFrom-IniToJson -InputPath $InputPath -OutputPath $tempJson
                if (-not (Get-Module -Name PSToml -ErrorAction SilentlyContinue)) {
                    throw "PSToml module is not available. Install it with: Install-Module PSToml"
                }
                $jsonObj = Get-Content -LiteralPath $tempJson -Raw | ConvertFrom-Json
                $toml = $jsonObj | ConvertTo-Toml -Depth 100
                if (-not $toml) {
                    throw "PSToml conversion failed"
                }
                Set-Content -LiteralPath $OutputPath -Value $toml -Encoding UTF8
            }
            finally {
                if ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and (Test-Path -LiteralPath $tempJson)) {
                    Remove-Item $tempJson -Force -ErrorAction SilentlyContinue
                }
            }
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.to-toml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.ini.to-toml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.ini.to-toml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    pstoml_available = (Get-Module -Name PSToml -ErrorAction SilentlyContinue) -ne $null
                }
            }
            else {
                Write-Error "Failed to convert INI to TOML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.to-toml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.ini.to-toml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # TOML to INI
    Set-Item -Path Function:Global:_ConvertTo-IniFromToml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.ini.from-toml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.toml$', '.ini'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.from-toml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # Convert TOML to JSON first, then JSON to INI
            $tempJson = [System.IO.Path]::GetTempFileName() + '.json'
            try {
                $json = & yq eval -o=json -p toml '.' $InputPath 2>$null
                if ($LASTEXITCODE -eq 0 -and $json) {
                    $json | Set-Content -LiteralPath $tempJson -Encoding UTF8
                    _ConvertTo-IniFromJson -InputPath $tempJson -OutputPath $OutputPath
                }
                else {
                    throw "yq command failed"
                }
            }
            finally {
                if ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and (Test-Path -LiteralPath $tempJson)) {
                    Remove-Item $tempJson -Force -ErrorAction SilentlyContinue
                }
            }
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.from-toml] Conversion completed in ${convDuration}ms"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.ini.from-toml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.ini.from-toml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                    yq_exit_code = $LASTEXITCODE
                }
            }
            else {
                Write-Error "Failed to convert TOML to INI: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.ini.from-toml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.ini.from-toml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert INI to JSON
<#
.SYNOPSIS
    Converts INI file to JSON format.
.DESCRIPTION
    Converts an INI (Initialization) file to JSON format.
.PARAMETER InputPath
    The path to the INI file.
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-IniToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-IniToJson @PSBoundParameters
}
Set-Alias -Name ini-to-json -Value ConvertFrom-IniToJson -ErrorAction SilentlyContinue

# Convert JSON to INI
<#
.SYNOPSIS
    Converts JSON file to INI format.
.DESCRIPTION
    Converts a JSON file to INI (Initialization) format.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output INI file. If not specified, uses input path with .ini extension.
#>
function ConvertTo-IniFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-IniFromJson @PSBoundParameters
}
Set-Alias -Name json-to-ini -Value ConvertTo-IniFromJson -ErrorAction SilentlyContinue

# Convert INI to YAML
<#
.SYNOPSIS
    Converts INI file to YAML format.
.DESCRIPTION
    Converts an INI (Initialization) file to YAML format.
.PARAMETER InputPath
    The path to the INI file.
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
#>
function ConvertFrom-IniToYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-IniToYaml @PSBoundParameters
}
Set-Alias -Name ini-to-yaml -Value ConvertFrom-IniToYaml -ErrorAction SilentlyContinue

# Convert YAML to INI
<#
.SYNOPSIS
    Converts YAML file to INI format.
.DESCRIPTION
    Converts a YAML file to INI (Initialization) format.
.PARAMETER InputPath
    The path to the YAML file.
.PARAMETER OutputPath
    The path for the output INI file. If not specified, uses input path with .ini extension.
#>
function ConvertTo-IniFromYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-IniFromYaml @PSBoundParameters
}
Set-Alias -Name yaml-to-ini -Value ConvertTo-IniFromYaml -ErrorAction SilentlyContinue

# Convert INI to XML
<#
.SYNOPSIS
    Converts INI file to XML format.
.DESCRIPTION
    Converts an INI (Initialization) file to XML format.
.PARAMETER InputPath
    The path to the INI file.
.PARAMETER OutputPath
    The path for the output XML file. If not specified, uses input path with .xml extension.
#>
function ConvertFrom-IniToXml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-IniToXml @PSBoundParameters
}
Set-Alias -Name ini-to-xml -Value ConvertFrom-IniToXml -ErrorAction SilentlyContinue

# Convert XML to INI
<#
.SYNOPSIS
    Converts XML file to INI format.
.DESCRIPTION
    Converts an XML file to INI (Initialization) format.
.PARAMETER InputPath
    The path to the XML file.
.PARAMETER OutputPath
    The path for the output INI file. If not specified, uses input path with .ini extension.
#>
function ConvertTo-IniFromXml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-IniFromXml @PSBoundParameters
}
Set-Alias -Name xml-to-ini -Value ConvertTo-IniFromXml -ErrorAction SilentlyContinue

# Convert INI to TOML
<#
.SYNOPSIS
    Converts INI file to TOML format.
.DESCRIPTION
    Converts an INI (Initialization) file to TOML format.
.PARAMETER InputPath
    The path to the INI file.
.PARAMETER OutputPath
    The path for the output TOML file. If not specified, uses input path with .toml extension.
#>
function ConvertFrom-IniToToml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-IniToToml @PSBoundParameters
}
Set-Alias -Name ini-to-toml -Value ConvertFrom-IniToToml -ErrorAction SilentlyContinue

# Convert TOML to INI
<#
.SYNOPSIS
    Converts TOML file to INI format.
.DESCRIPTION
    Converts a TOML file to INI (Initialization) format.
.PARAMETER InputPath
    The path to the TOML file.
.PARAMETER OutputPath
    The path for the output INI file. If not specified, uses input path with .ini extension.
#>
function ConvertTo-IniFromToml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-IniFromToml @PSBoundParameters
}
Set-Alias -Name toml-to-ini -Value ConvertTo-IniFromToml -ErrorAction SilentlyContinue

