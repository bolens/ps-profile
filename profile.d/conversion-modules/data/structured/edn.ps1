# ===============================================
# EDN (Extensible Data Notation) format conversion utilities
# EDN ↔ JSON, YAML
# ========================================

<#
.SYNOPSIS
    Initializes EDN format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for EDN (Extensible Data Notation) format.
    EDN is a data format used in Clojure, similar to JSON but with more data types.
    Supports bidirectional conversions between EDN and JSON, and conversions to YAML.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    EDN supports: keywords (:keyword), symbols, strings, numbers, booleans, nil, vectors [], maps {}, sets #{}, lists (), tagged literals.
    This implementation handles basic EDN structures (maps, vectors, lists, keywords, strings, numbers, booleans, nil).
#>
function Initialize-FileConversion-Edn {
    # Helper function to parse EDN content
    Set-Item -Path Function:Global:_Parse-Edn -Value {
        param([string]$EdnContent)
        
        # Remove comments (lines starting with ;)
        $lines = $EdnContent -split "`r?`n"
        $cleanedLines = @()
        foreach ($line in $lines) {
            $commentIndex = $line.IndexOf(';')
            if ($commentIndex -ge 0) {
                $line = $line.Substring(0, $commentIndex)
            }
            $cleanedLines += $line
        }
        $ednContent = $cleanedLines -join "`n"
        
        # Simple EDN parser - handles basic structures
        # This is a simplified parser that handles:
        # - Maps: {:key "value" :key2 123}
        # - Vectors: [1 2 3 "string"]
        # - Lists: (1 2 3)
        # - Keywords: :keyword
        # - Strings: "string"
        # - Numbers: 123, 123.45
        # - Booleans: true, false
        # - Nil: nil
        
        function Parse-EdnValue {
            param([string]$Content, [ref]$Index)
            
            $content = $Content.Trim()
            $pos = $Index.Value
            
            # Skip whitespace
            while ($pos -lt $content.Length -and [char]::IsWhiteSpace($content[$pos])) {
                $pos++
            }
            
            if ($pos -ge $content.Length) {
                return $null
            }
            
            $char = $content[$pos]
            
            # Parse map
            if ($char -eq '{') {
                $pos++
                $map = @{}
                while ($pos -lt $content.Length) {
                    # Skip whitespace
                    while ($pos -lt $content.Length -and [char]::IsWhiteSpace($content[$pos])) {
                        $pos++
                    }
                    if ($pos -ge $content.Length -or $content[$pos] -eq '}') {
                        $pos++
                        break
                    }
                    
                    # Parse key
                    $keyIndex = [ref]$pos
                    $key = Parse-EdnValue -Content $content -Index $keyIndex
                    $pos = $keyIndex.Value
                    
                    # Skip whitespace
                    while ($pos -lt $content.Length -and [char]::IsWhiteSpace($content[$pos])) {
                        $pos++
                    }
                    
                    # Parse value
                    $valueIndex = [ref]$pos
                    $value = Parse-EdnValue -Content $content -Index $valueIndex
                    $pos = $valueIndex.Value
                    
                    # Convert keyword to string
                    if ($key -is [string] -and $key.StartsWith(':')) {
                        $key = $key.Substring(1)
                    }
                    $map[$key] = $value
                    
                    # Skip whitespace
                    while ($pos -lt $content.Length -and [char]::IsWhiteSpace($content[$pos])) {
                        $pos++
                    }
                    if ($pos -lt $content.Length -and $content[$pos] -eq '}') {
                        $pos++
                        break
                    }
                }
                $Index.Value = $pos
                return $map
            }
            
            # Parse vector
            if ($char -eq '[') {
                $pos++
                $vector = @()
                while ($pos -lt $content.Length) {
                    # Skip whitespace
                    while ($pos -lt $content.Length -and [char]::IsWhiteSpace($content[$pos])) {
                        $pos++
                    }
                    if ($pos -ge $content.Length -or $content[$pos] -eq ']') {
                        $pos++
                        break
                    }
                    
                    $valueIndex = [ref]$pos
                    $value = Parse-EdnValue -Content $content -Index $valueIndex
                    $pos = $valueIndex.Value
                    if ($null -ne $value) {
                        $vector += $value
                    }
                    
                    # Skip whitespace
                    while ($pos -lt $content.Length -and [char]::IsWhiteSpace($content[$pos])) {
                        $pos++
                    }
                    if ($pos -lt $content.Length -and $content[$pos] -eq ']') {
                        $pos++
                        break
                    }
                }
                $Index.Value = $pos
                return $vector
            }
            
            # Parse list
            if ($char -eq '(') {
                $pos++
                $list = @()
                while ($pos -lt $content.Length) {
                    # Skip whitespace
                    while ($pos -lt $content.Length -and [char]::IsWhiteSpace($content[$pos])) {
                        $pos++
                    }
                    if ($pos -ge $content.Length -or $content[$pos] -eq ')') {
                        $pos++
                        break
                    }
                    
                    $valueIndex = [ref]$pos
                    $value = Parse-EdnValue -Content $content -Index $valueIndex
                    $pos = $valueIndex.Value
                    if ($null -ne $value) {
                        $list += $value
                    }
                    
                    # Skip whitespace
                    while ($pos -lt $content.Length -and [char]::IsWhiteSpace($content[$pos])) {
                        $pos++
                    }
                    if ($pos -lt $content.Length -and $content[$pos] -eq ')') {
                        $pos++
                        break
                    }
                }
                $Index.Value = $pos
                return $list
            }
            
            # Parse string
            if ($char -eq '"') {
                $pos++
                $str = ""
                $escaped = $false
                while ($pos -lt $content.Length) {
                    if ($escaped) {
                        if ($content[$pos] -eq 'n') { $str += "`n" }
                        elseif ($content[$pos] -eq 't') { $str += "`t" }
                        elseif ($content[$pos] -eq 'r') { $str += "`r" }
                        elseif ($content[$pos] -eq '\') { $str += '\' }
                        elseif ($content[$pos] -eq '"') { $str += '"' }
                        else { $str += $content[$pos] }
                        $escaped = $false
                    }
                    elseif ($content[$pos] -eq '\') {
                        $escaped = $true
                    }
                    elseif ($content[$pos] -eq '"') {
                        $pos++
                        break
                    }
                    else {
                        $str += $content[$pos]
                    }
                    $pos++
                }
                $Index.Value = $pos
                return $str
            }
            
            # Parse keyword
            if ($char -eq ':') {
                $pos++
                $keyword = ""
                while ($pos -lt $content.Length -and -not [char]::IsWhiteSpace($content[$pos]) -and 
                    $content[$pos] -ne '}' -and $content[$pos] -ne ']' -and $content[$pos] -ne ')' -and
                    $content[$pos] -ne ',' -and $content[$pos] -ne '{' -and $content[$pos] -ne '[' -and $content[$pos] -ne '(') {
                    $keyword += $content[$pos]
                    $pos++
                }
                $Index.Value = $pos
                return ":$keyword"
            }
            
            # Parse number or boolean or nil
            $token = ""
            while ($pos -lt $content.Length -and -not [char]::IsWhiteSpace($content[$pos]) -and 
                $content[$pos] -ne '}' -and $content[$pos] -ne ']' -and $content[$pos] -ne ')' -and
                $content[$pos] -ne ',' -and $content[$pos] -ne '{' -and $content[$pos] -ne '[' -and $content[$pos] -ne '(') {
                $token += $content[$pos]
                $pos++
            }
            
            if ($token -eq 'true') {
                $Index.Value = $pos
                return $true
            }
            if ($token -eq 'false') {
                $Index.Value = $pos
                return $false
            }
            if ($token -eq 'nil') {
                $Index.Value = $pos
                return $null
            }
            
            # Try to parse as number
            $number = 0
            if ([double]::TryParse($token, [ref]$number)) {
                $Index.Value = $pos
                return $number
            }
            
            # Return as string if nothing else matches
            $Index.Value = $pos
            return $token
        }
        
        $index = [ref]0
        return Parse-EdnValue -Content $ednContent -Index $index
    } -Force

    # Helper function to convert PowerShell object to EDN
    Set-Item -Path Function:Global:_ConvertTo-Edn -Value {
        param($Object)
        
        if ($null -eq $Object) {
            return 'nil'
        }
        if ($Object -is [bool]) {
            return $Object.ToString().ToLower()
        }
        if ($Object -is [string]) {
            # Escape string
            $escaped = $Object -replace '\\', '\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '\r' -replace "`t", '\t'
            return "`"$escaped`""
        }
        if ($Object -is [int] -or $Object -is [long] -or $Object -is [double] -or $Object -is [decimal]) {
            return $Object.ToString()
        }
        if ($Object -is [System.Collections.IDictionary] -or ($Object -is [PSCustomObject])) {
            $items = @()
            if ($Object -is [PSCustomObject]) {
                $Object.PSObject.Properties | ForEach-Object {
                    $key = $_.Name
                    $value = $_.Value
                    $ednKey = ":$key"
                    $ednValue = _ConvertTo-Edn -Object $value
                    $items += "$ednKey $ednValue"
                }
            }
            else {
                foreach ($key in $Object.Keys) {
                    $value = $Object[$key]
                    $ednKey = ":$key"
                    $ednValue = _ConvertTo-Edn -Object $value
                    $items += "$ednKey $ednValue"
                }
            }
            return "{ $($items -join ' ') }"
        }
        if ($Object -is [System.Collections.IList] -or $Object -is [System.Array]) {
            $items = @()
            foreach ($item in $Object) {
                $items += _ConvertTo-Edn -Object $item
            }
            return "[ $($items -join ' ') ]"
        }
        
        return $Object.ToString()
    } -Force

    # EDN to JSON
    Set-Item -Path Function:Global:_ConvertFrom-EdnToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.edn$', '.json' }
            
            $ednContent = Get-Content -LiteralPath $InputPath -Raw
            $parsed = _Parse-Edn -EdnContent $ednContent
            
            # Convert keywords in maps to regular strings
            function Convert-EdnToJsonObject {
                param($Item)
                if ($null -eq $Item) {
                    return $null
                }
                if ($Item -is [System.Collections.IDictionary]) {
                    $result = @{}
                    foreach ($key in $Item.Keys) {
                        $jsonKey = $key
                        if ($jsonKey -is [string] -and $jsonKey.StartsWith(':')) {
                            $jsonKey = $jsonKey.Substring(1)
                        }
                        $result[$jsonKey] = Convert-EdnToJsonObject -Item $Item[$key]
                    }
                    return $result
                }
                if ($Item -is [System.Collections.IList] -or $Item -is [System.Array]) {
                    $result = @()
                    foreach ($subItem in $Item) {
                        $result += Convert-EdnToJsonObject -Item $subItem
                    }
                    return $result
                }
                if ($Item -is [string] -and $Item.StartsWith(':')) {
                    return $Item.Substring(1)
                }
                return $Item
            }
            
            $jsonObj = Convert-EdnToJsonObject -Item $parsed
            $json = $jsonObj | ConvertTo-Json -Depth 100
            Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert EDN to JSON: $_"
            throw
        }
    } -Force

    # JSON to EDN
    Set-Item -Path Function:Global:_ConvertTo-EdnFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.edn' }
            
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            $ednContent = _ConvertTo-Edn -Object $jsonObj
            Set-Content -LiteralPath $OutputPath -Value $ednContent -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JSON to EDN: $_"
            throw
        }
    } -Force

    # EDN to YAML
    Set-Item -Path Function:Global:_ConvertFrom-EdnToYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.edn$', '.yaml' }
            
            # Convert EDN to JSON first, then to YAML
            $tempJson = Join-Path $env:TEMP "edn-to-yaml-$(Get-Random).json"
            try {
                _ConvertFrom-EdnToJson -InputPath $InputPath -OutputPath $tempJson
                
                # Convert JSON to YAML
                $jsonContent = Get-Content -LiteralPath $tempJson -Raw
                $jsonObj = $jsonContent | ConvertFrom-Json
                $yaml = $jsonObj | ConvertTo-Yaml -ErrorAction SilentlyContinue
                if (-not $yaml) {
                    # Fallback: simple key-value format
                    $yamlLines = @()
                    if ($jsonObj -is [PSCustomObject]) {
                        $jsonObj.PSObject.Properties | ForEach-Object {
                            $yamlLines += "$($_.Name): $($_.Value)"
                        }
                    }
                    $yaml = $yamlLines -join "`r`n"
                }
                Set-Content -LiteralPath $OutputPath -Value $yaml -Encoding UTF8
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert EDN to YAML: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert EDN to JSON
<#
.SYNOPSIS
    Converts EDN file to JSON format.
.DESCRIPTION
    Converts an EDN (Extensible Data Notation) file to JSON format.
    EDN is a data format used in Clojure, similar to JSON but with more data types.
.PARAMETER InputPath
    The path to the EDN file (.edn extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-EdnToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-EdnToJson @PSBoundParameters
}
Set-Alias -Name edn-to-json -Value ConvertFrom-EdnToJson -ErrorAction SilentlyContinue

# Convert JSON to EDN
<#
.SYNOPSIS
    Converts JSON file to EDN format.
.DESCRIPTION
    Converts a JSON file to EDN (Extensible Data Notation) format.
    EDN is a data format used in Clojure, similar to JSON but with more data types.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output EDN file. If not specified, uses input path with .edn extension.
#>
function ConvertTo-EdnFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-EdnFromJson @PSBoundParameters
}
Set-Alias -Name json-to-edn -Value ConvertTo-EdnFromJson -ErrorAction SilentlyContinue

# Convert EDN to YAML
<#
.SYNOPSIS
    Converts EDN file to YAML format.
.DESCRIPTION
    Converts an EDN (Extensible Data Notation) file to YAML format.
    Converts through JSON as an intermediate format.
.PARAMETER InputPath
    The path to the EDN file (.edn extension).
.PARAMETER OutputPath
    The path for the output YAML file. If not specified, uses input path with .yaml extension.
#>
function ConvertFrom-EdnToYaml {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-EdnToYaml @PSBoundParameters
}
Set-Alias -Name edn-to-yaml -Value ConvertFrom-EdnToYaml -ErrorAction SilentlyContinue
