# ===============================================
# Regular expression testing utilities
# ===============================================

<#
.SYNOPSIS
    Initializes regex testing utility functions.
.DESCRIPTION
    Sets up internal functions for testing regular expressions against input text.
    This function is called automatically by Ensure-DevTools.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-DevTools-Regex {
    $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
        Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
    }
    else {
        Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    }
    $global:DevToolsRegexUtilitiesPath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'RegexUtilities.psm1'

    # Natural language to regex converter
    Set-Item -Path Function:Global:_Ensure-RegexUtilitiesModule -Value {
        if (-not (Get-Module RegexUtilities -ErrorAction SilentlyContinue)) {
            if (-not (Test-Path -LiteralPath $global:DevToolsRegexUtilitiesPath)) {
                throw "RegexUtilities module not found at $($global:DevToolsRegexUtilitiesPath)"
            }
            Import-Module $global:DevToolsRegexUtilitiesPath -DisableNameChecking -ErrorAction Stop
        }
    } -Force

    Set-Item -Path Function:Global:_Invoke-RegexAiConversion -Value {
        param(
            [string]$Description,
            [string]$Model = 'llama3.2'
        )

        if (-not (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -or -not (Test-CachedCommand 'ollama')) {
            throw 'Ollama is not available for AI regex conversion. Install ollama or use rule-based conversion.'
        }

        $prompt = @"
Convert this natural language description into a .NET-compatible regular expression pattern.
Return only the regex pattern with no explanation, markdown, or delimiters.
Description: $Description
"@

        $response = (& ollama run $Model $prompt 2>&1 | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($response)) {
            throw 'AI regex conversion returned an empty response.'
        }

        _Ensure-RegexUtilitiesModule
        $resolved = Resolve-RegexPatternFromAiResponse -Response $response
        if (-not $resolved.IsValid) {
            throw "AI regex conversion produced an invalid pattern: $($resolved.Pattern)"
        }

        return $resolved.Pattern
    } -Force

    Set-Item -Path Function:Global:_Invoke-RegexAiExplanation -Value {
        param(
            [string]$Pattern,
            [string]$Model = 'llama3.2'
        )

        if (-not (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) -or -not (Test-CachedCommand 'ollama')) {
            throw 'Ollama is not available for AI regex explanation. Install ollama or use rule-based explanation.'
        }

        $prompt = @"
Explain this .NET-compatible regular expression pattern in plain English.
Use one or two concise sentences with no markdown.
Pattern: $Pattern
"@

        $response = (& ollama run $Model $prompt 2>&1 | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($response)) {
            throw 'AI regex explanation returned an empty response.'
        }

        return $response
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-RegexFromNaturalLanguage -Value {
        param(
            [string]$Description,
            [switch]$Anchored,
            [switch]$IgnoreCase,
            [switch]$PatternOnly,
            [string[]]$SampleMatch,
            [string[]]$SampleNoMatch,
            [switch]$UseAi,
            [switch]$TryAiFallback,
            [ValidateSet('Object', 'Text', 'Json')]
            [string]$OutputFormat = 'Object'
        )
        try {
            _Ensure-RegexUtilitiesModule

            $aiPattern = $null
            if ($UseAi) {
                $aiPattern = _Invoke-RegexAiConversion -Description $Description
            }

            $result = ConvertTo-RegexFromNaturalLanguage `
                -Description $Description `
                -Anchored:$Anchored `
                -IgnoreCase:$IgnoreCase `
                -SampleMatch $SampleMatch `
                -SampleNoMatch $SampleNoMatch `
                -AiPattern $aiPattern

            if ($TryAiFallback -and $result.NeedsAiFallback -and -not $UseAi) {
                $aiPattern = _Invoke-RegexAiConversion -Description $Description
                $result = ConvertTo-RegexFromNaturalLanguage `
                    -Description $Description `
                    -Anchored:$Anchored `
                    -IgnoreCase:$IgnoreCase `
                    -SampleMatch $SampleMatch `
                    -SampleNoMatch $SampleNoMatch `
                    -AiPattern $aiPattern
            }

            if (-not $result.IsValid) {
                throw "Generated regex pattern is invalid: $($result.Pattern)"
            }

            if ($PatternOnly) {
                return $result.Pattern
            }

            return Format-NaturalLanguageRegexResult -Result $result -As $OutputFormat
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.regex.nl-convert' -Context @{
                    description = $Description
                    useAi         = [bool]$UseAi.IsPresent
                    tryAiFallback = [bool]$TryAiFallback.IsPresent
                }
            }
            else {
                Write-Error "Failed to convert natural language to regex: $_" -ErrorAction Continue
            }
            throw
        }
    } -Force

    Set-Item -Path Function:Global:_Explain-RegexPattern -Value {
        param(
            [string]$Pattern,
            [switch]$Detailed,
            [switch]$UseAi,
            [ValidateSet('Object', 'Text', 'Json')]
            [string]$OutputFormat = 'Object'
        )

        try {
            _Ensure-RegexUtilitiesModule

            $result = ConvertFrom-RegexToNaturalLanguage -Pattern $Pattern -Detailed:$Detailed
            if ($UseAi -or ($result.Confidence -eq 'low' -and -not $Detailed)) {
                $aiDescription = _Invoke-RegexAiExplanation -Pattern $Pattern
                $result | Add-Member -NotePropertyName 'AiDescription' -NotePropertyValue $aiDescription -Force
                if ($UseAi -or $result.Confidence -eq 'low') {
                    $result.Description = $aiDescription
                    $result.Source = 'ai'
                    $result.Confidence = 'medium'
                }
            }

            return Format-NaturalLanguageRegexResult -Result $result -As $OutputFormat
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.regex.explain' -Context @{
                    pattern = $Pattern
                    useAi   = [bool]$UseAi.IsPresent
                }
            }
            else {
                Write-Error "Failed to explain regex pattern: $_" -ErrorAction Continue
            }
            throw
        }
    } -Force

    Set-Item -Path Function:Global:_Start-RegexDescriptionBuilder -Value {
        param(
            [string]$Description,
            [string[]]$Segments,
            [switch]$Alternation,
            [switch]$Anchored,
            [switch]$IgnoreCase,
            [string[]]$SampleMatch,
            [string[]]$SampleNoMatch,
            [string]$SessionPath,
            [switch]$SaveSession,
            [switch]$NonInteractive,
            [ValidateSet('Object', 'Text', 'Json')]
            [string]$OutputFormat = 'Object'
        )

        try {
            _Ensure-RegexUtilitiesModule

            $builtDescription = $Description
            if ([string]::IsNullOrWhiteSpace($builtDescription) -and $Segments -and $Segments.Count -gt 0) {
                $builtDescription = Build-NaturalLanguageRegexDescription -Segments $Segments -Alternation:$Alternation
            }

            if ([string]::IsNullOrWhiteSpace($builtDescription) -and $NonInteractive) {
                throw 'Non-interactive mode requires -Description or -Segments.'
            }

            if ([string]::IsNullOrWhiteSpace($builtDescription)) {
                Write-Host 'Regex Description Builder' -ForegroundColor Cyan
                Write-Host 'Modes: [1] Catalog  [2] Compose  [3] Either/Or' -ForegroundColor DarkGray
                $mode = (Read-Host 'Choose mode').Trim()

                switch ($mode) {
                    '1' {
                        $query = (Read-Host 'Catalog search or entry name').Trim()
                        $matches = @(Search-NaturalLanguageRegexCatalog -Query $query)
                        if ($matches.Count -eq 0) {
                            $catalogEntry = Resolve-NaturalLanguageRegexCatalogEntry -Phrase $query
                            if ($null -eq $catalogEntry) {
                                throw "No catalog entries matched '$query'."
                            }
                            $builtDescription = if ($catalogEntry.Aliases.Count -gt 0) { $catalogEntry.Aliases[0] } else { $catalogEntry.Name }
                        }
                        elseif ($matches.Count -eq 1) {
                            $builtDescription = if ($matches[0].Aliases.Count -gt 0) { $matches[0].Aliases[0] } else { $matches[0].Name }
                        }
                        else {
                            for ($i = 0; $i -lt $matches.Count; $i++) {
                                $aliasPreview = ($matches[$i].Aliases | Select-Object -First 1)
                                Write-Host ("[{0}] {1} - {2}" -f ($i + 1), $matches[$i].Name, $aliasPreview) -ForegroundColor DarkGray
                            }
                            $selection = [int](Read-Host 'Select entry number')
                            $selected = $matches[$selection - 1]
                            $builtDescription = if ($selected.Aliases.Count -gt 0) { $selected.Aliases[0] } else { $selected.Name }
                        }
                    }
                    '3' {
                        $options = [System.Collections.Generic.List[string]]::new()
                        do {
                            $segment = (Read-Host 'Option (blank to finish)').Trim()
                            if ([string]::IsNullOrWhiteSpace($segment)) {
                                break
                            }
                            $options.Add($segment)
                        } while ($true)
                        $builtDescription = Build-NaturalLanguageRegexDescription -Segments $options.ToArray() -Alternation
                    }
                    Default {
                        $segmentList = [System.Collections.Generic.List[string]]::new()
                        do {
                            $segment = (Read-Host 'Segment (blank to finish)').Trim()
                            if ([string]::IsNullOrWhiteSpace($segment)) {
                                break
                            }
                            $segmentList.Add($segment)
                        } while ($true)
                        $builtDescription = Build-NaturalLanguageRegexDescription -Segments $segmentList.ToArray()
                    }
                }

                $anchorResponse = (Read-Host 'Anchor to full input? [Y/n]').Trim()
                if ($anchorResponse -match '^(n|no)$') {
                    $Anchored = $false
                }
                else {
                    $Anchored = $true
                }

                $caseResponse = (Read-Host 'Case insensitive? [y/N]').Trim()
                if ($caseResponse -match '^(y|yes)$') {
                    $IgnoreCase = $true
                }
            }

            $sampleMatches = [System.Collections.Generic.List[string]]::new()
            $sampleNoMatches = [System.Collections.Generic.List[string]]::new()
            if ($SampleMatch) { $sampleMatches.AddRange($SampleMatch) }
            if ($SampleNoMatch) { $sampleNoMatches.AddRange($SampleNoMatch) }

            $conversion = _ConvertTo-RegexFromNaturalLanguage `
                -Description $builtDescription `
                -Anchored:$Anchored `
                -IgnoreCase:$IgnoreCase `
                -OutputFormat 'Object'

            Write-Host "Description: $builtDescription" -ForegroundColor Cyan
            Write-Host "Pattern: $($conversion.Pattern)" -ForegroundColor Green

            if (-not $NonInteractive -and [string]::IsNullOrWhiteSpace($Description) -and -not $Segments) {
                do {
                    $sample = (Read-Host 'Test sample (blank to finish)').Trim()
                    if ([string]::IsNullOrWhiteSpace($sample)) {
                        break
                    }

                    $match = Test-Regex -Pattern $conversion.Pattern -Input $sample -IgnoreCase:$conversion.IgnoreCase
                    $color = if ($match.Success) { 'Green' } else { 'Yellow' }
                    Write-Host ("Match: {0} Value: {1}" -f $match.Success, $match.Value) -ForegroundColor $color

                    $expectResponse = (Read-Host 'Should this sample match? [Y/n]').Trim()
                    if ($expectResponse -match '^(n|no)$') {
                        $sampleNoMatches.Add($sample)
                    }
                    else {
                        $sampleMatches.Add($sample)
                    }
                } while ($true)
            }

            $session = New-NaturalLanguageRegexSession `
                -Description $builtDescription `
                -Pattern $conversion.Pattern `
                -Segments @($Segments) `
                -Alternation:$Alternation `
                -Anchored:$Anchored `
                -IgnoreCase:$conversion.IgnoreCase `
                -SampleMatch $sampleMatches.ToArray() `
                -SampleNoMatch $sampleNoMatches.ToArray()

            $savedPath = $null
            if ($SaveSession -or -not [string]::IsNullOrWhiteSpace($SessionPath)) {
                $targetPath = if ([string]::IsNullOrWhiteSpace($SessionPath)) {
                    Join-Path (Get-Location).Path ("regex-session-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
                }
                else {
                    $SessionPath
                }
                $saved = Export-NaturalLanguageRegexSession -Session $session -Path $targetPath
                $savedPath = $saved.Path
                Write-Host "Session saved: $savedPath" -ForegroundColor Green
            }

            $result = [PSCustomObject]@{
                Description   = $builtDescription
                Pattern       = $conversion.Pattern
                Conversion    = $conversion
                Session       = $session
                SessionPath   = $savedPath
                SampleMatch   = $sampleMatches.ToArray()
                SampleNoMatch = $sampleNoMatches.ToArray()
            }

            if ($OutputFormat -eq 'Object') {
                return $result
            }

            return Format-NaturalLanguageRegexResult -Result $result -As $OutputFormat
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.regex.builder' -Context @{}
            }
            else {
                Write-Error "Regex description builder failed: $_" -ErrorAction Continue
            }
            throw
        }
    } -Force

    # Regex Tester
    Set-Item -Path Function:Global:_Test-Regex -Value {
        param(
            [string]$Pattern,
            [string]$InputText,
            [switch]$AllMatches,
            [switch]$IgnoreCase
        )
        try {
            $options = if ($IgnoreCase) { [System.Text.RegularExpressions.RegexOptions]::IgnoreCase } else { [System.Text.RegularExpressions.RegexOptions]::None }
            $regex = [System.Text.RegularExpressions.Regex]::new($Pattern, $options)
            if ($AllMatches) {
                $matches = $regex.Matches($InputText)
                $matches | ForEach-Object {
                    [PSCustomObject]@{
                        Value  = $_.Value
                        Index  = $_.Index
                        Length = $_.Length
                        Groups = $_.Groups | ForEach-Object { $_.Value }
                    }
                }
            }
            else {
                $match = $regex.Match($InputText)
                if ($match.Success) {
                    [PSCustomObject]@{
                        Success = $true
                        Value   = $match.Value
                        Index   = $match.Index
                        Length  = $match.Length
                        Groups  = $match.Groups | ForEach-Object { $_.Value }
                    }
                }
                else {
                    [PSCustomObject]@{
                        Success = $false
                        Value   = $null
                        Index   = -1
                        Length  = 0
                        Groups  = @()
                    }
                }
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.regex.match' -Context @{
                    pattern = $Pattern
                }
            }
            else {
                Write-Error "Invalid regex pattern: $_" -ErrorAction Continue
            }
            return [PSCustomObject]@{
                Success = $false
                Value   = $null
                Index   = -1
                Length  = 0
                Groups  = @()
            }
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Tests a regular expression against input text.
.DESCRIPTION
    Tests a regular expression pattern against input text and returns match results.
.PARAMETER Pattern
    The regular expression pattern to test.
.PARAMETER Input
    The input text to test against.
.PARAMETER AllMatches
    If specified, returns all matches instead of just the first.
.PARAMETER IgnoreCase
    If specified, performs case-insensitive matching.
.EXAMPLE
    Test-Regex -Pattern "\d+" -Input "Hello 123 World"
    Tests the pattern against the input and returns match details.
.EXAMPLE
    Test-Regex -Pattern "\w+" -Input "Hello World" -AllMatches
    Returns all word matches in the input.
.OUTPUTS
    PSCustomObject
    Object containing match information (Success, Value, Index, Length, Groups).
#>
function Test-Regex {
    param(
        [string]$Pattern,
        [Parameter(ValueFromPipeline = $true)]
        [string]$Input,
        [switch]$AllMatches,
        [switch]$IgnoreCase
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    # Rename Input to InputText to avoid conflict with $input
    $PSBoundParameters['InputText'] = $PSBoundParameters['Input']
    $PSBoundParameters.Remove('Input') | Out-Null
    _Test-Regex @PSBoundParameters
}
Set-AgentModeAlias -Name 'regex-test' -Target 'Test-Regex'

<#
.SYNOPSIS
    Converts a natural language description into a regular expression pattern.
.DESCRIPTION
    Translates common natural language regex descriptions into regular expression
    patterns. Supports catalog entries such as email, URL, IPv4, and UUID, plus
    compositional phrases such as "starts with user- followed by digits".
.PARAMETER Description
    Natural language description of the desired pattern.
.PARAMETER Anchored
    When specified, wraps the resulting pattern with ^ and $ if they are not already present.
.PARAMETER IgnoreCase
    When specified, marks the result as case-insensitive.
.PARAMETER PatternOnly
    When specified, returns only the regex pattern string instead of the full result object.
.PARAMETER SampleMatch
    Sample strings that should match the generated pattern.
.PARAMETER SampleNoMatch
    Sample strings that should not match the generated pattern.
.PARAMETER UseAi
    Uses Ollama to generate the regex pattern instead of rule-based conversion.
.PARAMETER TryAiFallback
    Uses Ollama when the rule-based converter cannot interpret the description.
.PARAMETER OutputFormat
    Output format for results: Object (default), Text, or Json.
.EXAMPLE
    ConvertTo-RegexFromDescription -Description 'email'
    Returns a regex pattern object for email addresses.
.EXAMPLE
    ConvertTo-RegexFromDescription -Description "starts with 'user-' followed by digits" -Anchored -PatternOnly
    Returns an anchored regex pattern string.
.EXAMPLE
    ConvertTo-RegexFromDescription -Description 'iban' -SampleMatch 'DE89370400440532013000' -SampleNoMatch 'not-an-iban'
    Returns a pattern and sample validation results.
.OUTPUTS
    PSCustomObject
    Object containing Pattern, Description, Source, IgnoreCase, Notes, IsValid, CatalogName,
    NeedsAiFallback, and optional SampleResults members.
    When -PatternOnly is specified, returns System.String.
#>
function ConvertTo-RegexFromDescription {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Description,
        [switch]$Anchored,
        [switch]$IgnoreCase,
        [switch]$PatternOnly,
        [string[]]$SampleMatch,
        [string[]]$SampleNoMatch,
        [switch]$UseAi,
        [switch]$TryAiFallback,
        [ValidateSet('Object', 'Text', 'Json')]
        [string]$OutputFormat = 'Object'
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _ConvertTo-RegexFromNaturalLanguage @PSBoundParameters
}
Set-AgentModeAlias -Name 'nl-to-regex' -Target 'ConvertTo-RegexFromDescription'
Set-AgentModeAlias -Name 'regex-from-description' -Target 'ConvertTo-RegexFromDescription'

<#
.SYNOPSIS
    Lists built-in natural language regex catalog entries.
.DESCRIPTION
    Returns catalog entries that map common descriptions to regex patterns.
.PARAMETER Name
    Optional catalog entry name to return a single entry.
.EXAMPLE
    Get-RegexDescriptionCatalog
    Lists all supported catalog entries.
.EXAMPLE
    Get-RegexDescriptionCatalog -Name 'iban'
    Returns the IBAN catalog entry.
.OUTPUTS
    PSCustomObject or ordered hashtable depending on whether -Name is specified.
#>
function Get-RegexDescriptionCatalog {
    [CmdletBinding()]
    param(
        [string]$Name
    )

    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Ensure-RegexUtilitiesModule

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return Get-NaturalLanguageRegexCatalogItems
    }

    $catalog = Get-NaturalLanguageRegexCatalog

    $normalizedName = $Name.Trim().ToLowerInvariant()
    if (-not $catalog.Contains($normalizedName)) {
        throw "Unknown regex catalog entry: $Name"
    }

    [PSCustomObject]@{
        Name    = $normalizedName
        Pattern = $catalog[$normalizedName].Pattern
        Aliases = $catalog[$normalizedName].Aliases
        Notes   = $catalog[$normalizedName].Notes
    }
}
Set-AgentModeAlias -Name 'regex-catalog' -Target 'Get-RegexDescriptionCatalog'

<#
.SYNOPSIS
    Searches natural language regex catalog entries.
.DESCRIPTION
    Finds catalog entries whose names or aliases match a query string.
.PARAMETER Query
    Search text to match against catalog names and aliases.
.EXAMPLE
    Search-RegexDescriptions -Query 'phone'
    Finds catalog entries related to phone numbers.
.OUTPUTS
    PSCustomObject[] with Name, Pattern, Aliases, Notes, and MatchType members.
#>
function Search-RegexDescriptions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Query
    )

    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Ensure-RegexUtilitiesModule
    Search-NaturalLanguageRegexCatalog -Query $Query
}
Set-AgentModeAlias -Name 'regex-catalog-search' -Target 'Search-RegexDescriptions'

<#
.SYNOPSIS
    Converts a natural language description to regex and tests it against input.
.DESCRIPTION
    Generates a regex pattern from a natural language description and immediately
    tests it against the provided input text.
.PARAMETER Description
    Natural language description of the desired pattern.
.PARAMETER InputText
    Input text to test against the generated pattern.
.PARAMETER Anchored
    When specified, wraps the resulting pattern with ^ and $.
.PARAMETER IgnoreCase
    When specified, performs case-insensitive matching.
.PARAMETER AllMatches
    When specified, returns all matches instead of only the first.
.PARAMETER UseAi
    Uses Ollama to generate the regex pattern.
.PARAMETER TryAiFallback
    Uses Ollama when the rule-based converter cannot interpret the description.
.EXAMPLE
    Test-RegexFromDescription -Description 'email' -Input 'user@example.com'
    Generates an email regex and tests the input.
.OUTPUTS
    PSCustomObject containing conversion details and match results.
#>
function Test-RegexFromDescription {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Description,
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [Alias('Input')]
        [string]$InputText,
        [switch]$Anchored,
        [switch]$IgnoreCase,
        [switch]$AllMatches,
        [switch]$UseAi,
        [switch]$TryAiFallback
    )

    if (-not $global:DevToolsInitialized) { Ensure-DevTools }

    $conversion = _ConvertTo-RegexFromNaturalLanguage `
        -Description $Description `
        -Anchored:$Anchored `
        -IgnoreCase:$IgnoreCase `
        -UseAi:$UseAi `
        -TryAiFallback:$TryAiFallback

    $matchParams = @{
        Pattern    = $conversion.Pattern
        Input      = $InputText
        AllMatches = $AllMatches
    }
    if ($conversion.IgnoreCase) {
        $matchParams['IgnoreCase'] = $true
    }

    $matchResult = Test-Regex @matchParams

    [PSCustomObject]@{
        Description  = $Description
        Pattern      = $conversion.Pattern
        Source       = $conversion.Source
        IgnoreCase   = $conversion.IgnoreCase
        CatalogName  = $conversion.CatalogName
        Match        = $matchResult
        IsValid      = $conversion.IsValid
        Notes        = $conversion.Notes
    }
}
Set-AgentModeAlias -Name 'regex-test-description' -Target 'Test-RegexFromDescription'

<#
.SYNOPSIS
    Displays natural language regex catalog entries in a table.
.DESCRIPTION
    Shows catalog entries with names, aliases, and notes. Optionally filters by query.
.PARAMETER Query
    Optional search text to filter catalog entries.
.PARAMETER IncludePattern
    When specified, includes the regex pattern column in the output table.
.EXAMPLE
    Show-RegexDescriptionCatalog
    Displays all catalog entries.
.EXAMPLE
    Show-RegexDescriptionCatalog -Query 'phone' -IncludePattern
    Displays phone-related catalog entries including patterns.
#>
function Show-RegexDescriptionCatalog {
    [CmdletBinding()]
    param(
        [string]$Query,
        [switch]$IncludePattern
    )

    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Ensure-RegexUtilitiesModule

    $entries = if ([string]::IsNullOrWhiteSpace($Query)) {
        Get-NaturalLanguageRegexCatalogItems
    }
    else {
        Search-NaturalLanguageRegexCatalog -Query $Query | ForEach-Object {
            [PSCustomObject]@{
                Name       = $_.Name
                Pattern    = $_.Pattern
                Aliases    = ($_.Aliases -join ', ')
                AliasCount = $_.Aliases.Count
                Notes      = ($_.Notes -join ' ')
            }
        }
    }

    $properties = @('Name', 'Aliases', 'AliasCount', 'Notes')
    if ($IncludePattern) {
        $properties = @('Name', 'Pattern', 'Aliases', 'Notes')
    }

    $entries | Sort-Object Name | Format-Table -Property $properties -AutoSize | Out-String | Write-Output
}
Set-AgentModeAlias -Name 'regex-catalog-show' -Target 'Show-RegexDescriptionCatalog'

<#
.SYNOPSIS
    Explains a regular expression pattern in plain language.
.DESCRIPTION
    Reverse direction of the natural language regex converter. Maps known catalog
    patterns back to descriptions and decomposes common regex constructs.
.PARAMETER Pattern
    Regular expression pattern to explain.
.PARAMETER Detailed
    When specified, includes per-component explanations.
.PARAMETER UseAi
    Uses Ollama to generate the explanation instead of rule-based decomposition.
.PARAMETER OutputFormat
    Output format for results: Object (default), Text, or Json.
.EXAMPLE
    Explain-RegexPattern -Pattern '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
    Explains an email regex pattern.
.EXAMPLE
    Explain-RegexPattern -Pattern '^user-\d+$' -OutputFormat Text
    Returns a plain-text explanation.
.OUTPUTS
    PSCustomObject, System.String, or JSON depending on -OutputFormat.
#>
function Explain-RegexPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Pattern,
        [switch]$Detailed,
        [switch]$UseAi,
        [ValidateSet('Object', 'Text', 'Json')]
        [string]$OutputFormat = 'Object'
    )

    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Explain-RegexPattern @PSBoundParameters
}
Set-AgentModeAlias -Name 'regex-explain' -Target 'Explain-RegexPattern'
Set-AgentModeAlias -Name 'regex-to-description' -Target 'Explain-RegexPattern'

<#
.SYNOPSIS
    Validates natural language regex description round-trip consistency.
.DESCRIPTION
    Converts a description to a regex pattern, explains it back to natural language,
    and scores similarity between the original and explained descriptions.
.PARAMETER Description
    Natural language description to validate.
.PARAMETER Anchored
    When specified, wraps the generated pattern with ^ and $.
.PARAMETER IgnoreCase
    When specified, marks the pattern as case-insensitive.
.PARAMETER MinimumSimilarity
    Minimum similarity score required for a consistent round-trip.
.PARAMETER OutputFormat
    Output format for results: Object (default), Text, or Json.
.EXAMPLE
    Test-RegexDescriptionRoundTrip -Description 'email'
    Validates round-trip consistency for an email description.
.OUTPUTS
    PSCustomObject with similarity and consistency metrics.
#>
function Test-RegexDescriptionRoundTrip {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Description,
        [switch]$Anchored,
        [switch]$IgnoreCase,
        [double]$MinimumSimilarity = 0.35,
        [ValidateSet('Object', 'Text', 'Json')]
        [string]$OutputFormat = 'Object'
    )

    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Ensure-RegexUtilitiesModule

    $result = Test-NaturalLanguageRegexRoundTrip `
        -Description $Description `
        -Anchored:$Anchored `
        -IgnoreCase:$IgnoreCase `
        -MinimumSimilarity $MinimumSimilarity

    Format-NaturalLanguageRegexResult -Result $result -As $OutputFormat
}
Set-AgentModeAlias -Name 'regex-roundtrip' -Target 'Test-RegexDescriptionRoundTrip'

<#
.SYNOPSIS
    Exports the natural language regex catalog to JSON or Markdown.
.DESCRIPTION
    Exports catalog entries with patterns, aliases, and notes. Optionally writes to a file.
.PARAMETER Format
    Export format: Json or Markdown.
.PARAMETER Path
    Optional output file path.
.EXAMPLE
    Export-RegexDescriptionCatalog -Format Markdown -Path ./regex-catalog.md
    Exports the catalog as Markdown.
.OUTPUTS
    System.String export contents.
#>
function Export-RegexDescriptionCatalog {
    [CmdletBinding()]
    param(
        [ValidateSet('Json', 'Markdown')]
        [string]$Format = 'Json',
        [string]$Path
    )

    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Ensure-RegexUtilitiesModule
    Export-NaturalLanguageRegexCatalogDocument -Format $Format -Path $Path
}
Set-AgentModeAlias -Name 'regex-catalog-export' -Target 'Export-RegexDescriptionCatalog'

<#
.SYNOPSIS
    Builds a natural language regex description interactively or from segments.
.DESCRIPTION
    Guides you through building a regex description from catalog entries, composed
    segments, or either/or options. Converts the result and optionally tests samples.
.PARAMETER Description
    Uses a pre-built description instead of prompting interactively.
.PARAMETER Segments
    Ordered phrase segments for non-interactive composition.
.PARAMETER Alternation
    When specified with -Segments, builds an either/or description.
.PARAMETER Anchored
    When specified, anchors the generated pattern to the full input.
.PARAMETER IgnoreCase
    When specified, marks the pattern as case-insensitive.
.PARAMETER SampleMatch
    Expected matching samples for the generated pattern.
.PARAMETER SampleNoMatch
    Expected non-matching samples for the generated pattern.
.PARAMETER SessionPath
    Optional path for saving the builder session as JSON.
.PARAMETER SaveSession
    When specified, saves the session to -SessionPath or an auto-generated file.
.PARAMETER NonInteractive
    Requires -Description or -Segments and skips prompts.
.PARAMETER OutputFormat
    Output format for results: Object (default), Text, or Json.
.EXAMPLE
    Start-RegexDescriptionBuilder
    Starts the interactive regex description builder.
.EXAMPLE
    Start-RegexDescriptionBuilder -Segments "starts with 'svc-'", 'digits' -Anchored -NonInteractive
    Builds and converts a description without prompts.
.EXAMPLE
    Start-RegexDescriptionBuilder -Description 'email' -SaveSession -SessionPath ./email-regex.json
    Builds and persists a regex session file.
.OUTPUTS
    PSCustomObject with Description, Pattern, Conversion, Session, and optional SessionPath members.
#>
function Start-RegexDescriptionBuilder {
    [CmdletBinding()]
    param(
        [string]$Description,
        [string[]]$Segments,
        [switch]$Alternation,
        [switch]$Anchored,
        [switch]$IgnoreCase,
        [string[]]$SampleMatch,
        [string[]]$SampleNoMatch,
        [string]$SessionPath,
        [switch]$SaveSession,
        [switch]$NonInteractive,
        [ValidateSet('Object', 'Text', 'Json')]
        [string]$OutputFormat = 'Object'
    )

    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Start-RegexDescriptionBuilder @PSBoundParameters
}
Set-AgentModeAlias -Name 'regex-builder' -Target 'Start-RegexDescriptionBuilder'

<#
.SYNOPSIS
    Saves a natural language regex session to a JSON file.
.DESCRIPTION
    Persists description, pattern, samples, and builder metadata for later reuse.
.PARAMETER Session
    Session object from Start-RegexDescriptionBuilder or New-NaturalLanguageRegexSession.
.PARAMETER Path
    Output JSON file path.
.EXAMPLE
    $builder = Start-RegexDescriptionBuilder -Description 'email' -NonInteractive
    Save-RegexDescriptionSession -Session $builder.Session -Path ./email.json
#>
function Save-RegexDescriptionSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        $Session,
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Ensure-RegexUtilitiesModule

    $sessionObject = if ($Session.PSObject.Properties.Name -contains 'Session') {
        $Session.Session
    }
    else {
        $Session
    }

    Export-NaturalLanguageRegexSession -Session $sessionObject -Path $Path
}
Set-AgentModeAlias -Name 'regex-session-save' -Target 'Save-RegexDescriptionSession'

<#
.SYNOPSIS
    Loads a saved natural language regex session from a JSON file.
.DESCRIPTION
    Imports a previously saved regex builder session.
.PARAMETER Path
    Path to the session JSON file.
.EXAMPLE
    Import-RegexDescriptionSession -Path ./email.json
#>
function Import-RegexDescriptionSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Ensure-RegexUtilitiesModule
    Import-NaturalLanguageRegexSession -Path $Path
}
Set-AgentModeAlias -Name 'regex-session-import' -Target 'Import-RegexDescriptionSession'

<#
.SYNOPSIS
    Resumes work from a saved natural language regex session.
.DESCRIPTION
    Loads a session file and optionally regenerates tests or re-runs the builder.
.PARAMETER Path
    Path to the session JSON file.
.PARAMETER Regenerate
    When specified, re-converts the stored description instead of using the saved pattern.
.PARAMETER GenerateTest
    When specified, generates a Pester stub from the session.
.PARAMETER TestPath
    Optional output path when -GenerateTest is specified.
.EXAMPLE
    Resume-RegexDescriptionSession -Path ./email.json
.EXAMPLE
    Resume-RegexDescriptionSession -Path ./email.json -GenerateTest -TestPath ./email.tests.ps1
#>
function Resume-RegexDescriptionSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [switch]$Regenerate,
        [switch]$GenerateTest,
        [string]$TestPath
    )

    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Ensure-RegexUtilitiesModule

    $session = Import-NaturalLanguageRegexSession -Path $Path
    $pattern = $session.Pattern

    if ($Regenerate) {
        $conversion = ConvertTo-RegexFromNaturalLanguage `
            -Description $session.Description `
            -Anchored:$session.Anchored `
            -IgnoreCase:$session.IgnoreCase
        $pattern = $conversion.Pattern
    }

    $result = [PSCustomObject]@{
        Session = $session
        Pattern = $pattern
    }

    if ($GenerateTest) {
        $testPath = if ([string]::IsNullOrWhiteSpace($TestPath)) {
            Join-Path (Split-Path -Parent $Path) ("{0}.tests.ps1" -f (Get-NaturalLanguageRegexTestSlug -Description $session.Description))
        }
        else {
            $TestPath
        }

        $stub = New-NaturalLanguageRegexPesterStub `
            -Description $session.Description `
            -Pattern $pattern `
            -SampleMatch $session.SampleMatch `
            -SampleNoMatch $session.SampleNoMatch `
            -Anchored:$session.Anchored `
            -IgnoreCase:$session.IgnoreCase `
            -Path $testPath

        $result | Add-Member -NotePropertyName 'TestPath' -NotePropertyValue $testPath -Force
        $result | Add-Member -NotePropertyName 'TestContent' -NotePropertyValue $stub -Force
        Write-Host "Pester stub written: $testPath" -ForegroundColor Green
    }

    Write-Host "Description: $($session.Description)" -ForegroundColor Cyan
    Write-Host "Pattern: $pattern" -ForegroundColor Green
    $result
}
Set-AgentModeAlias -Name 'regex-session-resume' -Target 'Resume-RegexDescriptionSession'

<#
.SYNOPSIS
    Compares two natural language regex descriptions.
.DESCRIPTION
    Shows token differences, similarity score, and optional generated pattern comparison.
.PARAMETER Left
    First natural language description.
.PARAMETER Right
    Second natural language description.
.PARAMETER IncludePatterns
    When specified, also compares generated regex patterns.
.PARAMETER ShowDiff
    When specified, writes a color-coded diff summary to the host.
.PARAMETER OutputFormat
    Output format for results: Object (default), Text, or Json.
.EXAMPLE
    Compare-RegexDescriptions -Left 'email' -Right 'email address' -IncludePatterns
#>
function Compare-RegexDescriptions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Left,
        [Parameter(Mandatory)]
        [string]$Right,
        [switch]$IncludePatterns,
        [switch]$Anchored,
        [switch]$IgnoreCase,
        [switch]$ShowDiff,
        [ValidateSet('Object', 'Text', 'Json')]
        [string]$OutputFormat = 'Object'
    )

    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Ensure-RegexUtilitiesModule

    $result = Compare-NaturalLanguageRegexDescriptions `
        -Left $Left `
        -Right $Right `
        -IncludePatterns:$IncludePatterns `
        -Anchored:$Anchored `
        -IgnoreCase:$IgnoreCase

    if ($ShowDiff) {
        Write-Host $result.DiffText -ForegroundColor Cyan
        if ($result.LeftOnlyTokens.Count -gt 0) {
            Write-Host ("- Left only: {0}" -f ($result.LeftOnlyTokens -join ', ')) -ForegroundColor Yellow
        }
        if ($result.RightOnlyTokens.Count -gt 0) {
            Write-Host ("+ Right only: {0}" -f ($result.RightOnlyTokens -join ', ')) -ForegroundColor Green
        }
    }

    if ($OutputFormat -eq 'Text') {
        return $result.DiffText
    }

    if ($OutputFormat -eq 'Json') {
        return ($result | ConvertTo-Json -Depth 6)
    }

    $result
}
Set-AgentModeAlias -Name 'regex-compare' -Target 'Compare-RegexDescriptions'

<#
.SYNOPSIS
    Generates a Pester test stub for a natural language regex description.
.DESCRIPTION
    Creates a standalone Pester test file from a description, pattern, and sample inputs.
.PARAMETER Description
    Natural language description of the desired pattern.
.PARAMETER Pattern
    Optional pre-generated regex pattern.
.PARAMETER SampleMatch
    Sample strings expected to match.
.PARAMETER SampleNoMatch
    Sample strings expected not to match.
.PARAMETER Path
    Optional output file path for the generated test stub.
.EXAMPLE
    New-RegexDescriptionPesterTest -Description 'email' -SampleMatch 'user@example.com' -SampleNoMatch 'invalid'
.EXAMPLE
    New-RegexDescriptionPesterTest -Description 'uuid' -Path ./uuid.tests.ps1
#>
function New-RegexDescriptionPesterTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Description,
        [string]$Pattern,
        [string[]]$SampleMatch,
        [string[]]$SampleNoMatch,
        [switch]$Anchored,
        [switch]$IgnoreCase,
        [string]$TestName,
        [string]$Path
    )

    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Ensure-RegexUtilitiesModule

    New-NaturalLanguageRegexPesterStub `
        -Description $Description `
        -Pattern $Pattern `
        -SampleMatch $SampleMatch `
        -SampleNoMatch $SampleNoMatch `
        -Anchored:$Anchored `
        -IgnoreCase:$IgnoreCase `
        -TestName $TestName `
        -Path $Path
}
Set-AgentModeAlias -Name 'regex-generate-test' -Target 'New-RegexDescriptionPesterTest'