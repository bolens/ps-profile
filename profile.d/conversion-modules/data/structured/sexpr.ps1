# ===============================================
# S-Expressions (Lisp-style) format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes S-Expressions format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for S-Expressions (Lisp-style) format conversions.
    S-Expressions are a notation for nested tree-structured data using parentheses.
    Supports conversions between S-Expressions and JSON, YAML, and other formats.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    S-Expressions support:
    - Lists: (item1 item2 item3)
    - Atoms: strings, numbers, symbols
    - Nested structures
    - Quoted strings: "string with spaces"
    - Comments: ; comment text
    Reference: https://en.wikipedia.org/wiki/S-expression
#>
function Initialize-FileConversion-Sexpr {
    # Helper function to parse S-Expression
    Set-Item -Path Function:Global:_Parse-Sexpr -Value {
        param([string]$SexprContent)
        
        # Remove comments (lines starting with ;)
        $lines = $SexprContent -split "`r?`n"
        $cleanedLines = @()
        foreach ($line in $lines) {
            $commentIndex = $line.IndexOf(';')
            if ($commentIndex -ge 0) {
                $line = $line.Substring(0, $commentIndex)
            }
            $cleanedLines += $line
        }
        $script:content = $cleanedLines -join "`n"
        
        $script:i = 0
        $script:len = $script:content.Length
        
        function SkipWhitespace {
            param([ref]$pos)
            while ($pos.Value -lt $script:len -and [char]::IsWhiteSpace($script:content[$pos.Value])) {
                $pos.Value++
            }
        }
        
        function ParseAtom {
            param([ref]$pos)
            SkipWhitespace -pos ([ref]$pos.Value)
            
            if ($pos.Value -ge $script:len) {
                return $null
            }
            
            $start = $pos.Value
            $char = $script:content[$pos.Value]
            
            # Quoted string
            if ($char -eq '"') {
                $pos.Value++
                $result = ''
                while ($pos.Value -lt $script:len) {
                    if ($script:content[$pos.Value] -eq '\' -and $pos.Value + 1 -lt $script:len) {
                        $next = $script:content[$pos.Value + 1]
                        switch ($next) {
                            'n' { $result += "`n"; $pos.Value += 2; continue }
                            't' { $result += "`t"; $pos.Value += 2; continue }
                            'r' { $result += "`r"; $pos.Value += 2; continue }
                            '\' { $result += '\'; $pos.Value += 2; continue }
                            '"' { $result += '"'; $pos.Value += 2; continue }
                            default { $result += $next; $pos.Value += 2; continue }
                        }
                    }
                    elseif ($script:content[$pos.Value] -eq '"') {
                        $pos.Value++
                        return $result
                    }
                    else {
                        $result += $script:content[$pos.Value]
                        $pos.Value++
                    }
                }
                return $result
            }
            
            # Number (integer or float)
            if ([char]::IsDigit($char) -or $char -eq '-' -or $char -eq '+') {
                $numStr = ''
                if ($char -eq '-' -or $char -eq '+') {
                    $numStr += $char
                    $pos.Value++
                }
                while ($pos.Value -lt $script:len -and [char]::IsDigit($script:content[$pos.Value])) {
                    $numStr += $script:content[$pos.Value]
                    $pos.Value++
                }
                if ($pos.Value -lt $script:len -and $script:content[$pos.Value] -eq '.') {
                    $numStr += '.'
                    $pos.Value++
                    while ($pos.Value -lt $script:len -and [char]::IsDigit($script:content[$pos.Value])) {
                        $numStr += $script:content[$pos.Value]
                        $pos.Value++
                    }
                    return [double]$numStr
                }
                return [long]$numStr
            }
            
            # Symbol or atom
            $atom = ''
            while ($pos.Value -lt $script:len -and 
                -not [char]::IsWhiteSpace($script:content[$pos.Value]) -and
                $script:content[$pos.Value] -ne '(' -and
                $script:content[$pos.Value] -ne ')' -and
                $script:content[$pos.Value] -ne '"') {
                $atom += $script:content[$pos.Value]
                $pos.Value++
            }
            
            # Try to parse as boolean
            if ($atom -eq 'true' -or $atom -eq '#t') {
                return $true
            }
            if ($atom -eq 'false' -or $atom -eq '#f') {
                return $false
            }
            if ($atom -eq 'nil' -or $atom -eq 'null') {
                return $null
            }
            
            return $atom
        }
        
        function ParseList {
            param([ref]$pos)
            SkipWhitespace -pos ([ref]$pos.Value)
            
            if ($pos.Value -ge $script:len -or $script:content[$pos.Value] -ne '(') {
                return $null
            }
            
            $pos.Value++ # Skip '('
            $list = @()
            
            SkipWhitespace -pos ([ref]$pos.Value)
            
            while ($pos.Value -lt $script:len -and $script:content[$pos.Value] -ne ')') {
                if ($script:content[$pos.Value] -eq '(') {
                    $sublist = ParseList -pos ([ref]$pos.Value)
                    if ($null -ne $sublist) {
                        $list += , $sublist
                    }
                }
                else {
                    $atom = ParseAtom -pos ([ref]$pos.Value)
                    if ($null -ne $atom) {
                        $list += $atom
                    }
                }
                SkipWhitespace -pos ([ref]$pos.Value)
            }
            
            if ($pos.Value -lt $script:len -and $script:content[$pos.Value] -eq ')') {
                $pos.Value++ # Skip ')'
            }
            
            return $list
        }
        
        SkipWhitespace -pos ([ref]$script:i)
        if ($script:i -ge $script:len) {
            return $null
        }
        
        if ($script:content[$script:i] -eq '(') {
            return ParseList -pos ([ref]$script:i)
        }
        else {
            return ParseAtom -pos ([ref]$script:i)
        }
    } -Force

    # Helper function to convert PowerShell object to S-Expression
    Set-Item -Path Function:Global:_ConvertTo-Sexpr -Value {
        param($Obj)
        
        if ($null -eq $Obj) {
            return 'nil'
        }
        
        $type = $Obj.GetType()
        
        if ($type -eq [bool]) {
            return if ($Obj) { 'true' } else { 'false' }
        }
        
        if ($type -eq [string]) {
            # Escape special characters
            $escaped = $Obj -replace '\\', '\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '\r' -replace "`t", '\t'
            return """$escaped"""
        }
        
        if ($type -eq [long] -or $type -eq [int] -or $type -eq [double] -or $type -eq [decimal]) {
            return $Obj.ToString()
        }
        
        if ($Obj -is [System.Collections.IList] -or $Obj -is [System.Array]) {
            $items = @()
            foreach ($item in $Obj) {
                $items += _ConvertTo-Sexpr -Obj $item
            }
            return '(' + ($items -join ' ') + ')'
        }
        
        if ($Obj -is [PSCustomObject] -or $Obj -is [Hashtable]) {
            $items = @()
            if ($Obj -is [Hashtable]) {
                foreach ($key in $Obj.Keys) {
                    $items += "($key " + (_ConvertTo-Sexpr -Obj $Obj[$key]) + ')'
                }
            }
            else {
                $Obj.PSObject.Properties | ForEach-Object {
                    $items += "($($_.Name) " + (_ConvertTo-Sexpr -Obj $_.Value) + ')'
                }
            }
            return '(' + ($items -join ' ') + ')'
        }
        
        return $Obj.ToString()
    } -Force

    # S-Expression to JSON
    Set-Item -Path Function:Global:_ConvertFrom-SexprToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(sexpr|sxp|lisp)$', '.json'
            }
            $sexprContent = Get-Content -LiteralPath $InputPath -Raw
            $parsed = _Parse-Sexpr -SexprContent $sexprContent
            
            # Convert parsed structure to JSON
            function ConvertToJsonObject {
                param($Item)
                if ($null -eq $Item) {
                    return $null
                }
                if ($Item -is [System.Collections.IList] -or $Item -is [System.Array]) {
                    $result = @()
                    foreach ($subItem in $Item) {
                        $result += ConvertToJsonObject -Item $subItem
                    }
                    return $result
                }
                return $Item
            }
            
            $jsonObj = ConvertToJsonObject -Item $parsed
            $json = $jsonObj | ConvertTo-Json -Depth 100
            Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert S-Expression to JSON: $_"
        }
    } -Force

    # JSON to S-Expression
    Set-Item -Path Function:Global:_ConvertTo-SexprFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.sexpr'
            }
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            $sexpr = _ConvertTo-Sexpr -Obj $jsonObj
            Set-Content -LiteralPath $OutputPath -Value $sexpr -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JSON to S-Expression: $_"
        }
    } -Force

    # S-Expression to YAML
    Set-Item -Path Function:Global:_ConvertFrom-SexprToYaml -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(sexpr|sxp|lisp)$', '.yaml'
            }
            $sexprContent = Get-Content -LiteralPath $InputPath -Raw
            $parsed = _Parse-Sexpr -SexprContent $sexprContent
            
            # Convert to JSON first, then to YAML (simple approach)
            function ConvertToJsonObject {
                param($Item)
                if ($null -eq $Item) {
                    return $null
                }
                if ($Item -is [System.Collections.IList] -or $Item -is [System.Array]) {
                    $result = @()
                    foreach ($subItem in $Item) {
                        $result += ConvertToJsonObject -Item $subItem
                    }
                    return $result
                }
                return $Item
            }
            
            $jsonObj = ConvertToJsonObject -Item $parsed
            $json = $jsonObj | ConvertTo-Json -Depth 100
            $yamlObj = $json | ConvertFrom-Json
            $yaml = $yamlObj | ConvertTo-Yaml -ErrorAction SilentlyContinue
            if (-not $yaml) {
                # Fallback: simple key-value format
                $yamlLines = @()
                if ($parsed -is [System.Collections.IList]) {
                    foreach ($item in $parsed) {
                        if ($item -is [System.Collections.IList] -and $item.Count -eq 2) {
                            $yamlLines += "$($item[0]): $($item[1])"
                        }
                    }
                }
                $yaml = $yamlLines -join "`r`n"
            }
            Set-Content -LiteralPath $OutputPath -Value $yaml -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert S-Expression to YAML: $_"
        }
    } -Force
}

