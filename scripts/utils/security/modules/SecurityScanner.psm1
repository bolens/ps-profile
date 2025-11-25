<#
scripts/utils/security/modules/SecurityScanner.psm1

.SYNOPSIS
    Security scanning utilities.

.DESCRIPTION
    Provides functions for scanning PowerShell files for security issues.
#>

<#
.SYNOPSIS
    Scans a PowerShell file for security issues.

.DESCRIPTION
    Analyzes a PowerShell file using PSScriptAnalyzer and pattern matching to detect security issues.

.PARAMETER FilePath
    Path to the PowerShell file to scan.

.PARAMETER SecurityRules
    Array of PSScriptAnalyzer rule names to use.

.PARAMETER ExternalCommandPatterns
    Hashtable of external command detection patterns.

.PARAMETER SecretPatterns
    Hashtable of secret detection patterns.

.PARAMETER FalsePositivePatterns
    Array of false positive detection patterns.

.PARAMETER Allowlist
    Allowlist hashtable for known-safe patterns.

.OUTPUTS
    Array of PSCustomObject with File, Rule, Severity, Line, and Message properties.
#>
function Invoke-SecurityScan {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string[]]$SecurityRules,

        [Parameter(Mandatory)]
        [hashtable]$ExternalCommandPatterns,

        [Parameter(Mandatory)]
        [hashtable]$SecretPatterns,

        [Parameter(Mandatory)]
        [string[]]$FalsePositivePatterns,

        [Parameter(Mandatory)]
        [hashtable]$Allowlist
    )

    # Import allowlist functions
    $allowlistModule = Join-Path $PSScriptRoot 'SecurityAllowlist.psm1'
    Import-Module $allowlistModule -ErrorAction Stop

    # Try to import Collections and FileContent modules from scripts/lib (optional)
    $libPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib'
    $collectionsModulePath = Join-Path $libPath 'Collections.psm1'
    $fileContentModulePath = Join-Path $libPath 'FileContent.psm1'
    if (Test-Path $collectionsModulePath) {
        Import-Module $collectionsModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
    if (Test-Path $fileContentModulePath) {
        Import-Module $fileContentModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }

    $fileIssues = if (Get-Command New-ObjectList -ErrorAction SilentlyContinue) {
        New-ObjectList
    }
    else {
        [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    try {
        # Run PSScriptAnalyzer
        $results = Invoke-ScriptAnalyzer -Path $FilePath -IncludeRule $SecurityRules -Severity Error, Warning -ErrorAction Stop
        if ($results) {
            foreach ($result in $results) {
                if ($null -ne $result) {
                    $fileIssues.Add([PSCustomObject]@{
                            File     = if ($null -ne $result.ScriptPath) { $result.ScriptPath } else { $FilePath }
                            Rule     = if ($null -ne $result.RuleName) { $result.RuleName } else { 'Unknown' }
                            Severity = if ($null -ne $result.Severity) { $result.Severity } else { 'Warning' }
                            Line     = if ($null -ne $result.Line) { $result.Line } else { 0 }
                            Message  = if ($null -ne $result.Message) { $result.Message } else { 'Security issue detected' }
                        })
                }
            }
        }

        # Use FileContent module if available, otherwise fallback
        if (Get-Command Read-FileContent -ErrorAction SilentlyContinue) {
            $content = Read-FileContent -Path $FilePath
        }
        else {
            $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
        }
        if ($content) {
            # Check for external command patterns
            $lineNumber = 0
            foreach ($line in ($content -split "`n")) {
                $lineNumber++

                # Skip null or empty lines
                if ([string]::IsNullOrEmpty($line)) {
                    continue
                }

                if ($null -ne $ExternalCommandPatterns) {
                    foreach ($patternName in $ExternalCommandPatterns.Keys) {
                        if ([string]::IsNullOrEmpty($patternName)) {
                            continue
                        }
                        $pattern = $ExternalCommandPatterns[$patternName]
                        if ($null -ne $pattern -and $pattern.IsMatch($line)) {
                            if ($line.TrimStart() -notmatch '^\s*#') {
                                $isAllowed = Test-AllowedCommand -Command $line -Allowlist $Allowlist

                                if (-not $isAllowed) {
                                    $isAllowed = Test-AllowedFile -FilePath $FilePath -Allowlist $Allowlist
                                }

                                if (-not $isAllowed) {
                                    $fileIssues.Add([PSCustomObject]@{
                                            File     = $FilePath
                                            Rule     = "ExternalCommand_$patternName"
                                            Severity = 'Warning'
                                            Line     = $lineNumber
                                            Message  = "Potential external command execution detected: $patternName. Review for security implications."
                                        })
                                }
                            }
                        }
                    }
                }

                # Check for secret patterns
                $lines = $content -split "`n"
                $lineNumber = 0
                foreach ($line in $lines) {
                    $lineNumber++

                    # Skip null or empty lines
                    if ([string]::IsNullOrEmpty($line)) {
                        continue
                    }

                    if ($null -ne $SecretPatterns) {
                        foreach ($patternName in $SecretPatterns.Keys) {
                            if ([string]::IsNullOrEmpty($patternName)) {
                                continue
                            }
                            $pattern = $SecretPatterns[$patternName]
                            if ($null -ne $pattern -and $pattern.IsMatch($line)) {
                                $trimmedLine = $line.TrimStart()
                                if ($trimmedLine -match '^\s*#') {
                                    continue
                                }

                                $codePart = if ($trimmedLine -match '^([^#]+)#' -and $null -ne $matches -and $matches.Count -gt 1 -and $null -ne $matches[1]) {
                                    $matches[1]
                                }
                                else {
                                    $trimmedLine
                                }

                                # Skip if codePart is null or empty
                                if ([string]::IsNullOrEmpty($codePart)) {
                                    continue
                                }

                                $isAllowed = Test-AllowedSecretPattern -Line $line -Allowlist $Allowlist

                                if (-not $isAllowed) {
                                    $isAllowed = Test-AllowedFile -FilePath $FilePath -Allowlist $Allowlist
                                }

                                if (-not $isAllowed) {
                                    $lowerLine = $codePart.ToLower()

                                    if ($null -ne $FalsePositivePatterns) {
                                        foreach ($fpPattern in $FalsePositivePatterns) {
                                            if (-not [string]::IsNullOrEmpty($fpPattern) -and $lowerLine -match $fpPattern) {
                                                $isAllowed = $true
                                                break
                                            }
                                        }
                                    }

                                    if (-not $isAllowed) {
                                        if ($lineNumber -gt 1) {
                                            $prevLineObj = $lines[$lineNumber - 2]
                                            if ($null -ne $prevLineObj) {
                                                $prevLine = $prevLineObj.ToLower()
                                                if ($prevLine -match '(?:example|sample|test|placeholder|demo|fake|dummy|mock|temporary|temp)') {
                                                    $isAllowed = $true
                                                }
                                            }
                                        }

                                        if (-not $isAllowed -and $lineNumber -lt $lines.Count) {
                                            $nextLineObj = $lines[$lineNumber]
                                            if ($null -ne $nextLineObj) {
                                                $nextLine = $nextLineObj.ToLower()
                                                if ($nextLine -match '(?:example|sample|test|placeholder|demo|fake|dummy|mock|temporary|temp)') {
                                                    $isAllowed = $true
                                                }
                                            }
                                        }

                                        if (-not $isAllowed) {
                                            $match = $pattern.Match($codePart)
                                            if ($null -ne $match -and $match.Success -and $match.Groups.Count -gt 1) {
                                                $capturedGroup = $match.Groups[1]
                                                if ($null -ne $capturedGroup) {
                                                    $capturedValue = $capturedGroup.Value

                                                    if ($null -ne $capturedValue -and $capturedValue.Length -gt 0) {
                                                        $isSimpleWord = $capturedValue -match '^[a-z]+$' -and $capturedValue.Length -lt 15
                                                        $isRepeating = $capturedValue -match '^(.)\1+$'
                                                        $hasHighEntropy = ($capturedValue -match '[A-Z]') -and ($capturedValue -match '[a-z]') -and ($capturedValue -match '[0-9]')

                                                        if ($isSimpleWord -or $isRepeating) {
                                                            $isAllowed = $true
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                if (-not $isAllowed) {
                                    $fileIssues.Add([PSCustomObject]@{
                                            File     = $FilePath
                                            Rule     = "HardcodedSecret_$patternName"
                                            Severity = 'Error'
                                            Line     = $lineNumber
                                            Message  = "Potential hardcoded secret detected: $patternName"
                                        })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    catch {
        $fileIssues.Add([PSCustomObject]@{
                File     = $FilePath
                Rule     = 'ScanError'
                Severity = 'Error'
                Line     = 0
                Message  = "Failed to scan: $($_.Exception.Message)"
            })
    }

    return $fileIssues.ToArray()
}

Export-ModuleMember -Function Invoke-SecurityScan

