# ===============================================
# TOON (Token-Oriented Object Notation) conversion helper utilities
# JSON ↔ TOON conversion helpers
# ===============================================
# TOON is a compact data format that removes redundant JSON syntax (brackets, braces)
# to reduce token usage in AI/LLM contexts while maintaining readability.
# These helpers convert between JSON and TOON formats for efficient data representation.

# JSON to TOON conversion function
<#
.SYNOPSIS
    Converts a JSON object to TOON format.
.DESCRIPTION
    Converts a PowerShell object (from JSON) to TOON (Token-Oriented Object Notation) format,
    which removes redundant JSON syntax like brackets and braces to reduce token usage.
.PARAMETER JsonObject
    The PowerShell object to convert to TOON format.
.PARAMETER Indent
    The indentation level for nested structures (internal use).
.OUTPUTS
    String representing the TOON format.
#>
function Convert-JsonToToon {
    param(
        [Parameter(Mandatory)]
        $JsonObject,
        [int]$Indent = 0
    )

    $indentStr = '  ' * $Indent
    $result = @()

    # Handle object/hashtable: convert to TOON key-value format (no braces)
    if ($JsonObject -is [PSCustomObject] -or $JsonObject -is [hashtable]) {
        $props = @()
        foreach ($key in $JsonObject.PSObject.Properties.Name) {
            $value = $JsonObject.$key
            # Quote key only if it contains special characters
            $keyStr = if ($key -match '^[a-zA-Z_][a-zA-Z0-9_]*$') { $key } else { "`"$key`"" }
            
            # Recursively convert nested objects
            if ($value -is [PSCustomObject] -or $value -is [hashtable]) {
                $nested = Convert-JsonToToon -JsonObject $value -Indent ($Indent + 1)
                $props += "$indentStr$keyStr`n$nested"
            }
            # Convert arrays: use '-' prefix for items (no brackets)
            elseif ($value -is [array]) {
                $arrayItems = @()
                foreach ($item in $value) {
                    if ($item -is [PSCustomObject] -or $item -is [hashtable]) {
                        $nested = Convert-JsonToToon -JsonObject $item -Indent ($Indent + 1)
                        $arrayItems += "$indentStr-`n$nested"
                    }
                    else {
                        $valStr = if ($item -is [string]) { "`"$($item -replace '"', '\"')`"" } elseif ($null -eq $item) { 'null' } else { $item.ToString() }
                        $arrayItems += "$indentStr- $valStr"
                    }
                }
                $props += "$keyStr`n" + ($arrayItems -join "`n")
            }
            # Handle primitive values
            elseif ($null -eq $value) {
                $props += "$indentStr$keyStr null"
            }
            elseif ($value -is [string]) {
                # Escape special characters in strings
                $escaped = $value -replace '"', '\"' -replace "`n", '\n' -replace "`r", ''
                $props += "$indentStr$keyStr `"$escaped`""
            }
            elseif ($value -is [bool]) {
                $props += "$indentStr$keyStr $($value.ToString().ToLower())"
            }
            else {
                $props += "$indentStr$keyStr $value"
            }
        }
        $result = $props -join "`n"
    }
    # Handle top-level arrays: convert to TOON list format (no brackets)
    elseif ($JsonObject -is [array]) {
        $items = @()
        foreach ($item in $JsonObject) {
            if ($item -is [PSCustomObject] -or $item -is [hashtable]) {
                $nested = Convert-JsonToToon -JsonObject $item -Indent ($Indent + 1)
                $items += "$indentStr-`n$nested"
            }
            else {
                $valStr = if ($item -is [string]) { "`"$($item -replace '"', '\"')`"" } elseif ($null -eq $item) { 'null' } else { $item.ToString() }
                $items += "$indentStr- $valStr"
            }
        }
        $result = $items -join "`n"
    }
    # Handle primitive values (strings, numbers, booleans)
    else {
        $valStr = if ($JsonObject -is [string]) { "`"$($JsonObject -replace '"', '\"')`"" } elseif ($null -eq $JsonObject) { 'null' } else { $JsonObject.ToString() }
        $result = "$indentStr$valStr"
    }

    return $result
}

# TOON to JSON helper function
<#
.SYNOPSIS
    Converts TOON format to a JSON-compatible PowerShell object.
.DESCRIPTION
    Parses TOON (Token-Oriented Object Notation) format and converts it back to a PowerShell object
    that can be serialized to JSON.
.PARAMETER ToonString
    The TOON format string to parse.
.OUTPUTS
    PowerShell object representing the parsed TOON data.
#>
function Convert-ToonToJson {
    param(
        [Parameter(Mandatory)]
        [string]$ToonString
    )

    $lines = $ToonString -split "`n" | Where-Object { $_.Trim() -ne '' }
    $result = Parse-ToonLines -Lines $lines -Index 0
    return $result.Object
}

# Parse TOON lines helper function
<#
.SYNOPSIS
    Parses TOON format lines into a PowerShell object structure.
.DESCRIPTION
    Recursively parses TOON format lines, handling nested objects and arrays.
    This is an internal helper function used by Convert-ToonToJson.
.PARAMETER Lines
    Array of TOON format lines to parse.
.PARAMETER Index
    Starting index in the lines array.
.PARAMETER BaseIndent
    Base indentation level for the current parsing context.
.OUTPUTS
    Hashtable with 'Object' (the parsed object) and 'Index' (the next index to process).
#>
function Parse-ToonLines {
    param(
        [string[]]$Lines,
        [int]$Index,
        [int]$BaseIndent = 0
    )

    $obj = [ordered]@{}
    $array = @()
    $isArray = $false
    $i = $Index

    while ($i -lt $Lines.Length) {
        $line = $Lines[$i]
        $trimmed = $line.TrimStart()
        $indent = $line.Length - $trimmed.Length

        if ($indent -lt $BaseIndent) {
            break
        }

        if ($trimmed.StartsWith('-')) {
            $isArray = $true
            $valuePart = $trimmed.Substring(1).Trim()
            
            if ($valuePart -eq '') {
                # Nested object/array
                $i++
                if ($i -ge $Lines.Length) {
                    continue
                }
                
                $nextLine = $Lines[$i]
                $nextIndent = $nextLine.Length - $nextLine.TrimStart().Length
                $parsed = Parse-ToonLines -Lines $Lines -Index $i -BaseIndent $nextIndent
                $array += $parsed.Object
                $i = $parsed.Index
            }
            else {
                # Simple value
                $array += Parse-ToonValue -Value $valuePart
                $i++
            }
        }
        elseif ($trimmed -match '^([^:]+):\s*(.+)$') {
            $key = $matches[1].Trim('"')
            $valueStr = $matches[2].Trim()
            
            if ($valueStr -eq '') {
                # Nested object
                $i++
                if ($i -ge $Lines.Length) {
                    continue
                }
                
                $nextLine = $Lines[$i]
                $nextIndent = $nextLine.Length - $nextLine.TrimStart().Length
                $parsed = Parse-ToonLines -Lines $Lines -Index $i -BaseIndent $nextIndent
                $obj[$key] = $parsed.Object
                $i = $parsed.Index
            }
            else {
                $obj[$key] = Parse-ToonValue -Value $valueStr
                $i++
            }
        }
        else {
            # Key without colon (might be followed by nested structure)
            $key = $trimmed.Trim('"')
            $i++
            if ($i -ge $Lines.Length) {
                $obj[$key] = $null
                continue
            }
            
            $nextLine = $Lines[$i]
            $nextIndent = $nextLine.Length - $nextLine.TrimStart().Length
            if ($nextIndent -gt $indent) {
                $parsed = Parse-ToonLines -Lines $Lines -Index $i -BaseIndent $nextIndent
                $obj[$key] = $parsed.Object
                $i = $parsed.Index
            }
            else {
                $obj[$key] = $null
            }
        }
    }

    if ($isArray) {
        return @{ Object = $array; Index = $i }
    }
    else {
        return @{ Object = [PSCustomObject]$obj; Index = $i }
    }
}

# Parse TOON value helper function
<#
.SYNOPSIS
    Parses a single TOON value string into a PowerShell object.
.DESCRIPTION
    Converts a TOON value string (number, string, boolean, null) into the appropriate PowerShell type.
    This is an internal helper function used by Parse-ToonLines.
.PARAMETER Value
    The TOON value string to parse.
.OUTPUTS
    The parsed value as a PowerShell object (string, int, double, bool, or null).
#>
function Parse-ToonValue {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $trimmed = $Value.Trim()
    
    if ($trimmed -eq 'null') {
        return $null
    }
    elseif ($trimmed -eq 'true') {
        return $true
    }
    elseif ($trimmed -eq 'false') {
        return $false
    }
    elseif ($trimmed.StartsWith('"') -and $trimmed.EndsWith('"')) {
        try {
            $str = $trimmed.Substring(1, $trimmed.Length - 2)
            return $str -replace '\\"', '"' -replace '\\n', "`n"
        }
        catch {
            # If substring fails (shouldn't happen, but be safe), return trimmed value
            return $trimmed
        }
    }
    elseif ($trimmed -match '^-?\d+$') {
        try {
            return [int]$trimmed
        }
        catch {
            # Fallback to string if int conversion fails
            return $trimmed
        }
    }
    elseif ($trimmed -match '^-?\d+\.\d+$') {
        try {
            return [double]$trimmed
        }
        catch {
            # Fallback to string if double conversion fails
            return $trimmed
        }
    }
    else {
        return $trimmed
    }
}

