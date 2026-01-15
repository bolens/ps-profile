# ===============================================
# Java Properties file format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Java Properties file format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Java Properties file format conversions.
    Properties files are used in Java applications to store configuration in key=value format.
    Supports conversions between Properties and JSON, YAML, INI, and other formats.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Properties files support:
    - Comments (lines starting with # or !)
    - Key=value pairs
    - Escaped characters (\n, \t, \\, \uXXXX for Unicode)
    - Multi-line values (using trailing backslash)
    - Whitespace around = is ignored
    Reference: https://docs.oracle.com/javase/8/docs/api/java/util/Properties.html
#>
function Initialize-FileConversion-Properties {
    # Helper function to unescape Properties value
    Set-Item -Path Function:Global:_Unescape-PropertiesValue -Value {
        param([string]$Value)
        if ([string]::IsNullOrEmpty($Value)) {
            return $Value
        }
        $result = ''
        $i = 0
        while ($i -lt $Value.Length) {
            if ($Value[$i] -eq '\' -and $i -lt $Value.Length - 1) {
                $next = $Value[$i + 1]
                switch ($next) {
                    'n' { $result += "`n"; $i += 2; continue }
                    't' { $result += "`t"; $i += 2; continue }
                    'r' { $result += "`r"; $i += 2; continue }
                    'f' { $result += "`f"; $i += 2; continue }
                    '\' { $result += '\'; $i += 2; continue }
                    'u' {
                        # Unicode escape \uXXXX
                        if ($i + 5 -lt $Value.Length) {
                            $hex = $Value.Substring($i + 2, 4)
                            try {
                                $codePoint = [Convert]::ToInt32($hex, 16)
                                $result += [char]::ConvertFromUtf32($codePoint)
                                $i += 6
                                continue
                            }
                            catch {
                                # Invalid Unicode escape, treat as literal
                                $result += '\u'
                                $i += 2
                                continue
                            }
                        }
                        else {
                            $result += '\u'
                            $i += 2
                            continue
                        }
                    }
                    default {
                        # Unknown escape, treat backslash as literal
                        $result += '\'
                        $i++
                        continue
                    }
                }
            }
            else {
                $result += $Value[$i]
                $i++
            }
        }
        return $result
    } -Force

    # Helper function to escape Properties value
    Set-Item -Path Function:Global:_Escape-PropertiesValue -Value {
        param([string]$Value)
        if ([string]::IsNullOrEmpty($Value)) {
            return $Value
        }
        $result = ''
        foreach ($char in $Value.ToCharArray()) {
            switch ($char) {
                '\' { $result += '\\'; continue }
                '\n' { $result += '\n'; continue }
                '\r' { $result += '\r'; continue }
                '\t' { $result += '\t'; continue }
                '\f' { $result += '\f'; continue }
                ' ' { $result += ' '; continue }
                '=' { $result += '\='; continue }
                ':' { $result += '\:'; continue }
                '#' { $result += '\#'; continue }
                '!' { $result += '\!'; continue }
                default {
                    $codePoint = [int][char]$char
                    if ($codePoint -gt 127) {
                        # Unicode character - use \uXXXX
                        $result += '\u' + $codePoint.ToString('X4')
                    }
                    else {
                        $result += $char
                    }
                }
            }
        }
        return $result
    } -Force

    # Helper function to parse Properties file
    Set-Item -Path Function:Global:_Parse-PropertiesFile -Value {
        param([string]$PropertiesContent)
        $result = @{}
        $lines = $PropertiesContent -split "`r?`n"
        $currentKey = $null
        $currentValue = ''
        
        foreach ($line in $lines) {
            $trimmedLine = $line.Trim()
            
            # Skip empty lines
            if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
                continue
            }
            
            # Skip comments (lines starting with # or !)
            if ($trimmedLine.StartsWith('#') -or $trimmedLine.StartsWith('!')) {
                continue
            }
            
            # Check for continuation (line ending with backslash)
            if ($line.EndsWith('\') -and $null -ne $currentKey) {
                # Remove trailing backslash and add to current value
                $currentValue += $line.Substring(0, $line.Length - 1).TrimEnd()
                continue
            }
            
            # Save previous key-value if exists
            if ($null -ne $currentKey) {
                $result[$currentKey] = _Unescape-PropertiesValue -Value $currentValue.Trim()
                $currentKey = $null
                $currentValue = ''
            }
            
            # Check for key=value or key:value pair
            if ($trimmedLine -match '^([^=:]+)[=:](.*)$') {
                $currentKey = $matches[1].Trim()
                $currentValue = $matches[2]
            }
            elseif ($trimmedLine -match '^([^=:\s]+)\s*$') {
                # Key without value
                $currentKey = $matches[1].Trim()
                $currentValue = ''
            }
        }
        
        # Save last key-value
        if ($null -ne $currentKey) {
            $result[$currentKey] = _Unescape-PropertiesValue -Value $currentValue.Trim()
        }
        
        return $result
    } -Force

    # Properties to JSON
    Set-Item -Path Function:Global:_ConvertFrom-PropertiesToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.properties.to-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.properties$', '.json'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.to-json] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $propertiesContent = Get-Content -LiteralPath $InputPath -Raw
            $propertiesData = _Parse-PropertiesFile -PropertiesContent $propertiesContent
            
            $jsonObj = [PSCustomObject]$propertiesData
            $json = $jsonObj | ConvertTo-Json -Depth 100
            Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.to-json] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.properties.to-json] Properties found: $($propertiesData.Keys.Count)"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.properties.to-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Properties: $($propertiesData.Keys.Count)" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.properties.to-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert Properties to JSON: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.to-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.properties.to-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # JSON to Properties
    Set-Item -Path Function:Global:_ConvertTo-PropertiesFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.properties.from-json] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.properties'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.from-json] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            $propertiesLines = @()
            $propertyCount = 0
            $jsonObj.PSObject.Properties | ForEach-Object {
                $key = $_.Name
                $value = $_.Value
                
                # Escape key and value
                $escapedKey = _Escape-PropertiesValue -Value $key
                $escapedValue = _Escape-PropertiesValue -Value ([string]$value)
                
                $propertiesLines += "$escapedKey=$escapedValue"
                $propertyCount++
            }
            
            $propertiesContent = $propertiesLines -join "`r`n"
            Set-Content -LiteralPath $OutputPath -Value $propertiesContent -Encoding UTF8
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.from-json] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.properties.from-json] Properties created: $propertyCount"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.properties.from-json] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Properties: $propertyCount" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.properties.from-json' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert JSON to Properties: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.from-json] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.properties.from-json] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # Properties to YAML
    Set-Item -Path Function:Global:_ConvertFrom-PropertiesToYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.properties.to-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.properties$', '.yaml'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.to-yaml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $propertiesContent = Get-Content -LiteralPath $InputPath -Raw
            $propertiesData = _Parse-PropertiesFile -PropertiesContent $propertiesContent
            
            # Convert to YAML (simple key-value format)
            $yamlLines = @()
            foreach ($key in $propertiesData.Keys | Sort-Object) {
                $value = $propertiesData[$key]
                $yamlLines += "${key}: $value"
            }
            
            $yamlContent = $yamlLines -join "`r`n"
            Set-Content -LiteralPath $OutputPath -Value $yamlContent -Encoding UTF8
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.to-yaml] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.properties.to-yaml] Properties converted: $($propertiesData.Keys.Count)"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.properties.to-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Properties: $($propertiesData.Keys.Count)" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.properties.to-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert Properties to YAML: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.to-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.properties.to-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # YAML to Properties
    Set-Item -Path Function:Global:_ConvertTo-PropertiesFromYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.properties.from-yaml] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ya?ml$', '.properties'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.from-yaml] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            # For simple YAML, parse as key-value pairs
            $yamlContent = Get-Content -LiteralPath $InputPath -Raw
            $propertiesData = @{}
            
            $lines = $yamlContent -split "`r?`n"
            $lineCount = $lines.Count
            foreach ($line in $lines) {
                $trimmedLine = $line.Trim()
                if ([string]::IsNullOrWhiteSpace($trimmedLine) -or $trimmedLine.StartsWith('#')) {
                    continue
                }
                if ($trimmedLine -match '^([^:]+):\s*(.*)$') {
                    $key = $matches[1].Trim()
                    $value = $matches[2].Trim()
                    $propertiesData[$key] = $value
                }
            }
            
            $propertiesLines = @()
            foreach ($key in $propertiesData.Keys | Sort-Object) {
                $value = $propertiesData[$key]
                $escapedKey = _Escape-PropertiesValue -Value $key
                $escapedValue = _Escape-PropertiesValue -Value $value
                $propertiesLines += "$escapedKey=$escapedValue"
            }
            
            $propertiesContent = $propertiesLines -join "`r`n"
            Set-Content -LiteralPath $OutputPath -Value $propertiesContent -Encoding UTF8
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.from-yaml] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.properties.from-yaml] Properties created: $($propertiesData.Keys.Count), YAML lines processed: $lineCount"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.properties.from-yaml] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Properties: $($propertiesData.Keys.Count), Lines: $lineCount" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.properties.from-yaml' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert YAML to Properties: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.from-yaml] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.properties.from-yaml] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # Properties to INI
    Set-Item -Path Function:Global:_ConvertFrom-PropertiesToIni -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.properties.to-ini] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.properties$', '.ini'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.to-ini] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $propertiesContent = Get-Content -LiteralPath $InputPath -Raw
            $propertiesData = _Parse-PropertiesFile -PropertiesContent $propertiesContent
            
            # Properties files don't have sections, so put everything in a default section
            $iniLines = @()
            $iniLines += '[default]'
            foreach ($key in $propertiesData.Keys | Sort-Object) {
                $value = $propertiesData[$key]
                $iniLines += "$key=$value"
            }
            
            $iniContent = $iniLines -join "`r`n"
            Set-Content -LiteralPath $OutputPath -Value $iniContent -Encoding UTF8
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.to-ini] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.properties.to-ini] Properties converted: $($propertiesData.Keys.Count)"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.properties.to-ini] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Properties: $($propertiesData.Keys.Count)" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.properties.to-ini' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert Properties to INI: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.to-ini] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.properties.to-ini] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force

    # INI to Properties
    Set-Item -Path Function:Global:_ConvertTo-PropertiesFromIni -Value {
        param([string]$InputPath, [string]$OutputPath)
        
        # Parse debug level once at function start
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            # Debug is enabled
        }
        
        try {
            # Level 1: Basic operation start
            if ($debugLevel -ge 1) {
                Write-Verbose "[conversion.properties.from-ini] Starting conversion: $InputPath"
            }
            
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.ini$', '.properties'
            }
            
            # Level 2: Operation context
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.from-ini] Output path: $OutputPath"
            }
            
            $convStartTime = Get-Date
            $iniContent = Get-Content -LiteralPath $InputPath -Raw
            $propertiesData = @{}
            
            $lines = $iniContent -split "`r?`n"
            $lineCount = $lines.Count
            foreach ($line in $lines) {
                $trimmedLine = $line.Trim()
                if ([string]::IsNullOrWhiteSpace($trimmedLine) -or $trimmedLine.StartsWith(';') -or $trimmedLine.StartsWith('#')) {
                    continue
                }
                if ($trimmedLine -match '^\[(.+)\]$') {
                    # Section header - Properties files don't support sections, so we skip them
                    continue
                }
                if ($trimmedLine -match '^([^=]+)=(.*)$') {
                    $key = $matches[1].Trim()
                    $value = $matches[2].Trim()
                    $propertiesData[$key] = $value
                }
            }
            
            $propertiesLines = @()
            foreach ($key in $propertiesData.Keys | Sort-Object) {
                $value = $propertiesData[$key]
                $escapedKey = _Escape-PropertiesValue -Value $key
                $escapedValue = _Escape-PropertiesValue -Value $value
                $propertiesLines += "$escapedKey=$escapedValue"
            }
            
            $propertiesContent = $propertiesLines -join "`r`n"
            Set-Content -LiteralPath $OutputPath -Value $propertiesContent -Encoding UTF8
            
            $convDuration = ((Get-Date) - $convStartTime).TotalMilliseconds
            
            # Level 2: Timing information
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.from-ini] Conversion completed in ${convDuration}ms"
                Write-Verbose "[conversion.properties.from-ini] Properties created: $($propertiesData.Keys.Count), INI lines processed: $lineCount"
            }
            
            # Level 3: Performance breakdown
            if ($debugLevel -ge 3) {
                $inputSize = if (Test-Path -LiteralPath $InputPath) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                $outputSize = if (Test-Path -LiteralPath $OutputPath) { (Get-Item -LiteralPath $OutputPath).Length } else { 0 }
                Write-Host "  [conversion.properties.from-ini] Performance - Duration: ${convDuration}ms, Input: ${inputSize} bytes, Output: ${outputSize} bytes, Properties: $($propertiesData.Keys.Count), Lines: $lineCount" -ForegroundColor DarkGray
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                $inputSize = if ($InputPath -and (Test-Path -LiteralPath $InputPath)) { (Get-Item -LiteralPath $InputPath).Length } else { 0 }
                Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.properties.from-ini' -Context @{
                    input_path = $InputPath
                    output_path = $OutputPath
                    input_size_bytes = $inputSize
                    error_type = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to convert INI to Properties: $_"
            }
            
            # Level 2: Error details
            if ($debugLevel -ge 2) {
                Write-Verbose "[conversion.properties.from-ini] Error type: $($_.Exception.GetType().FullName)"
            }
            
            # Level 3: Stack trace
            if ($debugLevel -ge 3) {
                Write-Host "  [conversion.properties.from-ini] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
            
            throw
        }
    } -Force
}

