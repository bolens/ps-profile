<#
scripts/utils/security/modules/SecurityAllowlist.psm1

.SYNOPSIS
    Security allowlist management utilities.

.DESCRIPTION
    Provides functions for loading and managing security allowlists for known-safe patterns.
#>

<#
.SYNOPSIS
    Gets the default security allowlist.

.DESCRIPTION
    Returns the default allowlist with common safe external commands, secret patterns, and file patterns.

.OUTPUTS
    Hashtable with ExternalCommands, SecretPatterns, and FilePatterns properties.
#>
function Get-DefaultAllowlist {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
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
}

<#
.SYNOPSIS
    Loads allowlist from a JSON file.

.DESCRIPTION
    Loads a custom allowlist from a JSON file and merges it with the default allowlist.

.PARAMETER AllowlistFile
    Path to the JSON allowlist file.

.PARAMETER DefaultAllowlist
    Default allowlist to merge with.

.OUTPUTS
    Hashtable with merged allowlist data.
#>
function Get-AllowlistFromFile {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$AllowlistFile,

        [Parameter(Mandatory)]
        [hashtable]$DefaultAllowlist
    )

    if (-not (Test-Path -Path $AllowlistFile)) {
        return $DefaultAllowlist
    }

    try {
        $customAllowlist = Get-Content -Path $AllowlistFile -Raw | ConvertFrom-Json
        $mergedAllowlist = $DefaultAllowlist.Clone()

        if ($customAllowlist.ExternalCommands) {
            $mergedAllowlist.ExternalCommands += $customAllowlist.ExternalCommands
        }
        if ($customAllowlist.SecretPatterns) {
            $mergedAllowlist.SecretPatterns += $customAllowlist.SecretPatterns
        }
        if ($customAllowlist.FilePatterns) {
            $mergedAllowlist.FilePatterns += $customAllowlist.FilePatterns
        }

        Write-ScriptMessage -Message "Loaded allowlist from: $AllowlistFile" -LogLevel Info
        return $mergedAllowlist
    }
    catch {
        Write-ScriptMessage -Message "Failed to load allowlist file: $($_.Exception.Message)" -IsWarning
        return $DefaultAllowlist
    }
}

<#
.SYNOPSIS
    Checks if a command is in the allowlist.

.DESCRIPTION
    Determines if an external command is allowed based on the allowlist.

.PARAMETER Command
    Command name to check.

.PARAMETER Allowlist
    Allowlist hashtable.

.OUTPUTS
    System.Boolean. True if the command is allowed, false otherwise.
#>
function Test-AllowedCommand {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(Mandatory)]
        [hashtable]$Allowlist
    )

    foreach ($allowedCmd in $Allowlist.ExternalCommands) {
        if ($Command -match [regex]::Escape($allowedCmd)) {
            return $true
        }
    }

    return $false
}

<#
.SYNOPSIS
    Checks if a file matches an allowed file pattern.

.DESCRIPTION
    Determines if a file path matches any of the allowed file patterns.

.PARAMETER FilePath
    File path to check.

.PARAMETER Allowlist
    Allowlist hashtable.

.OUTPUTS
    System.Boolean. True if the file matches an allowed pattern, false otherwise.
#>
function Test-AllowedFile {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [hashtable]$Allowlist
    )

    foreach ($filePattern in $Allowlist.FilePatterns) {
        if ($FilePath -match $filePattern) {
            return $true
        }
    }

    return $false
}

<#
.SYNOPSIS
    Checks if a line matches an allowed secret pattern.

.DESCRIPTION
    Determines if a line matches any of the allowed secret patterns (e.g., example passwords).

.PARAMETER Line
    Line content to check.

.PARAMETER Allowlist
    Allowlist hashtable.

.OUTPUTS
    System.Boolean. True if the line matches an allowed pattern, false otherwise.
#>
function Test-AllowedSecretPattern {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Line,

        [Parameter(Mandatory)]
        [hashtable]$Allowlist
    )

    foreach ($allowedPattern in $Allowlist.SecretPatterns) {
        if ($Line -match $allowedPattern) {
            return $true
        }
    }

    return $false
}

Export-ModuleMember -Function Get-DefaultAllowlist, Get-AllowlistFromFile, Test-AllowedCommand, Test-AllowedFile, Test-AllowedSecretPattern

