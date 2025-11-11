<#
scripts/utils/run-security-scan.ps1

.SYNOPSIS
    Runs security-focused analysis on PowerShell scripts using PSScriptAnalyzer.

.DESCRIPTION
    Runs security-focused analysis on PowerShell scripts using PSScriptAnalyzer with
    security-specific rules. Checks for common security issues like plain text passwords,
    use of Invoke-Expression, and other security anti-patterns.

.PARAMETER Path
    The path to scan. Defaults to profile.d directory relative to repository root.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-security-scan.ps1

    Runs security scan on all PowerShell files in the profile.d directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-security-scan.ps1 -Path scripts

    Runs security scan on all PowerShell files in the scripts directory.
#>

param(
    [ValidateScript({
            if ($_ -and -not (Test-Path $_)) {
                throw "Path does not exist: $_"
            }
            $true
        })]
    [string]$Path = $null,

    [string]$AllowlistFile = $null
)

# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

# Default to profile.d relative to the repository root
try {
    $defaultPath = Get-ProfileDirectory -ScriptPath $PSScriptRoot
    $Path = Resolve-DefaultPath -Path $Path -DefaultPath $defaultPath -PathType 'Directory'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Write-ScriptMessage -Message "Running security scan on: $Path"

# Ensure PSScriptAnalyzer is available
try {
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Load allowlist for known-safe patterns
$allowlist = @{
    ExternalCommands = @(
        'git',
        'pwsh',
        'powershell',
        'npm',
        'npx',
        'cargo',
        'cspell',
        'markdownlint',
        'git-cliff'
    )
    SecretPatterns   = @(
        'password\s*=\s*["'']?example',
        'password\s*=\s*["'']?test',
        'password\s*=\s*["'']?placeholder',
        'api_key\s*=\s*["'']?your.*key',
        'token\s*=\s*["'']?your.*token'
    )
    FilePatterns     = @(
        '\.tests\.ps1$',
        '\.test\.ps1$',
        'test-.*\.ps1$'
    )
}

# Load custom allowlist file if provided
if ($AllowlistFile -and (Test-Path -Path $AllowlistFile)) {
    try {
        $customAllowlist = Get-Content -Path $AllowlistFile -Raw | ConvertFrom-Json
        if ($customAllowlist.ExternalCommands) {
            $allowlist.ExternalCommands += $customAllowlist.ExternalCommands
        }
        if ($customAllowlist.SecretPatterns) {
            $allowlist.SecretPatterns += $customAllowlist.SecretPatterns
        }
        if ($customAllowlist.FilePatterns) {
            $allowlist.FilePatterns += $customAllowlist.FilePatterns
        }
        Write-ScriptMessage -Message "Loaded allowlist from: $AllowlistFile" -LogLevel Info
    }
    catch {
        Write-ScriptMessage -Message "Failed to load allowlist file: $($_.Exception.Message)" -IsWarning
    }
}

# Security-focused rules (expanded set)
$securityRules = @(
    'PSAvoidUsingConvertToSecureStringWithPlainText',
    'PSAvoidUsingPlainTextForPassword',
    'PSAvoidUsingUserNameAndPasswordParams',
    'PSUsePSCredentialType',
    'PSAvoidUsingInvokeExpression',
    'PSAvoidUsingPositionalParameters',
    'PSAvoidUsingEmptyCatchBlock',
    'PSAvoidUsingWMICmdlet',
    'PSAvoidUsingDeprecatedManifestFields',
    'PSAvoidGlobalVars',
    'PSAvoidUsingWriteHost',
    'PSUseDeclaredVarsMoreThanAssignments',
    'PSAvoidDefaultValueForMandatoryParameter',
    'PSAvoidUsingCmdletAliases',
    'PSAvoidUsingComputerNameHardcoded',
    'PSAvoidUsingPlainTextForPassword',
    'PSUseShouldProcessForStateChangingFunctions',
    'PSAvoidNullOrEmptyHelpMessageAttribute'
) | Select-Object -Unique

# Use List for better performance than array concatenation
$securityIssues = [System.Collections.Generic.List[PSCustomObject]]::new()

# Get PowerShell scripts using helper function
$scripts = Get-PowerShellScripts -Path $Path

# Process files sequentially for reliability
Write-ScriptMessage -Message "Scanning $($scripts.Count) file(s) for security issues..."

$externalCommandPatterns = @{
    'InvokeExpression' = [regex]::new('Invoke-Expression\s+', [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    'StartProcess'     = [regex]::new('Start-Process\s+.*-FilePath\s+["'']([^"'']+)["'']', [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    'CallOperator'     = [regex]::new('&\s+\$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    'DynamicCommand'   = [regex]::new('&?\s*\([^)]+\)\s*\(', [System.Text.RegularExpressions.RegexOptions]::Compiled)
}

$passwordPattern = '(?:password|passwd|pwd)\s*[=:]\s*["'']?([^"'']{8,})["'']?'
$apiKeyPattern = '(?:apikey|api_key|api-key)\s*[=:]\s*["'']?(?!.*(?:example|sample|test|placeholder|your|changeme|replace|demo|fake|dummy|mock))([A-Za-z0-9]{20,})["'']?'
$tokenPattern = '(?:token|access_token)\s*[=:]\s*["'']?(?!.*(?:example|sample|test|placeholder|your|changeme|replace|demo|fake|dummy|mock))([A-Za-z0-9]{20,})["'']?'
$secretPattern = '(?:secret|secretkey|secret_key)\s*[=:]\s*["'']?(?!.*(?:example|sample|test|placeholder|your|changeme|replace|demo|fake|dummy|mock))([A-Za-z0-9]{16,})["'']?'
$awsKeyPattern = 'AKIA[0-9A-Z]{16}(?!.*(?:example|test|sample|placeholder))'
$privateKeyPattern = '-----BEGIN\s+(?:RSA\s+)?PRIVATE\s+KEY-----(?!.*(?:test|example|sample|placeholder))'

$secretPatterns = @{
    'HardcodedPassword' = [regex]::new($passwordPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    'HardcodedAPIKey'   = [regex]::new($apiKeyPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    'HardcodedToken'    = [regex]::new($tokenPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    'HardcodedSecret'   = [regex]::new($secretPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    'AWSKeyPattern'     = [regex]::new($awsKeyPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)
    'PrivateKeyPattern' = [regex]::new($privateKeyPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)
}

$falsePositivePatterns = @(
    '(?:example|sample|test|placeholder|your[_-]?|changeme|replace|demo|fake|dummy|mock|temp|temporary)',
    '(?:test[_-]?(?:data|value|key|token|secret|password|api))',
    '(?:#|//|/\*|\*/\s*example|\s*example\s*$)',
    '(?:\$example|\$sample|\$test|\$placeholder|\$demo)',
    '(?:["''](?:example|test|sample|placeholder|your|changeme)[^"'']*["'']|["''][^"'']*(?:example|test|sample|placeholder|your|changeme)["''])'
)

$scanResults = foreach ($script in $scripts) {
    $file = $script.FullName
    $fileIssues = [System.Collections.Generic.List[PSCustomObject]]::new()

    try {
        $results = Invoke-ScriptAnalyzer -Path $file -IncludeRule $securityRules -Severity Error, Warning -ErrorAction Stop
        if ($results) {
            foreach ($result in $results) {
                $fileIssues.Add([PSCustomObject]@{
                        File     = $result.ScriptPath
                        Rule     = $result.RuleName
                        Severity = $result.Severity
                        Line     = $result.Line
                        Message  = $result.Message
                    })
            }
        }

        $content = Get-Content -Path $file -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $lineNumber = 0
            foreach ($line in ($content -split "`n")) {
                $lineNumber++

                foreach ($patternName in $externalCommandPatterns.Keys) {
                    $pattern = $externalCommandPatterns[$patternName]
                    if ($pattern.IsMatch($line)) {
                        if ($line.TrimStart() -notmatch '^\s*#') {
                            $isAllowed = $false
                            foreach ($allowedCmd in $allowlist.ExternalCommands) {
                                if ($line -match [regex]::Escape($allowedCmd)) {
                                    $isAllowed = $true
                                    break
                                }
                            }

                            if (-not $isAllowed) {
                                foreach ($filePattern in $allowlist.FilePatterns) {
                                    if ($file -match $filePattern) {
                                        $isAllowed = $true
                                        break
                                    }
                                }
                            }

                            if (-not $isAllowed) {
                                $fileIssues.Add([PSCustomObject]@{
                                        File     = $file
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

            $lines = $content -split "`n"
            $lineNumber = 0
            foreach ($line in $lines) {
                $lineNumber++

                foreach ($patternName in $secretPatterns.Keys) {
                    $pattern = $secretPatterns[$patternName]
                    if ($pattern.IsMatch($line)) {
                        $trimmedLine = $line.TrimStart()
                        if ($trimmedLine -match '^\s*#') {
                            continue
                        }

                        $codePart = if ($trimmedLine -match '^([^#]+)#') { $matches[1] } else { $trimmedLine }

                        $isAllowed = $false
                        foreach ($allowedPattern in $allowlist.SecretPatterns) {
                            if ($line -match $allowedPattern) {
                                $isAllowed = $true
                                break
                            }
                        }

                        if (-not $isAllowed) {
                            foreach ($filePattern in $allowlist.FilePatterns) {
                                if ($file -match $filePattern) {
                                    $isAllowed = $true
                                    break
                                }
                            }
                        }

                        if (-not $isAllowed) {
                            $lowerLine = $codePart.ToLower()

                            foreach ($fpPattern in $falsePositivePatterns) {
                                if ($lowerLine -match $fpPattern) {
                                    $isAllowed = $true
                                    break
                                }
                            }

                            if (-not $isAllowed) {
                                if ($lineNumber -gt 1) {
                                    $prevLine = $lines[$lineNumber - 2].ToLower()
                                    if ($prevLine -match '(?:example|sample|test|placeholder|demo|fake|dummy|mock|temporary|temp)') {
                                        $isAllowed = $true
                                    }
                                }

                                if (-not $isAllowed -and $lineNumber -lt $lines.Count) {
                                    $nextLine = $lines[$lineNumber].ToLower()
                                    if ($nextLine -match '(?:example|sample|test|placeholder|demo|fake|dummy|mock|temporary|temp)') {
                                        $isAllowed = $true
                                    }
                                }

                                if (-not $isAllowed) {
                                    $match = $pattern.Match($codePart)
                                    if ($match.Success -and $match.Groups.Count -gt 1) {
                                        $capturedValue = $match.Groups[1].Value

                                        if ($capturedValue.Length -gt 0) {
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

                        if (-not $isAllowed) {
                            $fileIssues.Add([PSCustomObject]@{
                                    File     = $file
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
    catch {
        $fileIssues.Add([PSCustomObject]@{
                File     = $file
                Rule     = 'ScanError'
                Severity = 'Error'
                Line     = 0
                Message  = "Failed to scan: $($_.Exception.Message)"
            })
    }

    @{
        File   = $file
        Issues = $fileIssues.ToArray()
    }
}

# Collect results and handle errors
foreach ($result in $scanResults) {
    if ($result.Issues) {
        foreach ($issue in $result.Issues) {
            # Resolve relative path for display
            try {
                $relativePath = Resolve-Path -Relative $issue.File -ErrorAction SilentlyContinue
                if ($relativePath) {
                    $issue.File = $relativePath
                }
            }
            catch {
                # Keep absolute path if relative resolution fails
            }

            $securityIssues.Add($issue)

            # Check for scan errors
            if ($issue.Rule -eq 'ScanError') {
                Write-ScriptMessage -Message "Failed to scan $($result.File): $($issue.Message)" -IsWarning
            }
        }
    }
}

# Check for scan errors that should cause failure
$scanErrors = $securityIssues | Where-Object { $_.Rule -eq 'ScanError' }
if ($scanErrors.Count -gt 0) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to scan $($scanErrors.Count) file(s). Check warnings above for details."
}

$blockingIssues = $securityIssues | Where-Object { $_.Severity -eq 'Error' }
$warningIssues = $securityIssues | Where-Object { $_.Severity -ne 'Error' }

if ($blockingIssues.Count -gt 0) {
    Write-ScriptMessage -Message "`nSecurity Issues (Errors):"
    $blockingIssues | Format-Table -AutoSize

    if ($warningIssues.Count -gt 0) {
        Write-ScriptMessage -Message "`nSecurity Warnings:" -LogLevel Info
        $warningIssues | Format-Table -AutoSize
    }

    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Found $($blockingIssues.Count) security-related error(s)"
}

if ($warningIssues.Count -gt 0) {
    Write-ScriptMessage -Message "`nSecurity Warnings:" -LogLevel Info
    $warningIssues | Format-Table -AutoSize
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Security scan completed with $($warningIssues.Count) warning(s)"
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Security scan completed: no issues found"

