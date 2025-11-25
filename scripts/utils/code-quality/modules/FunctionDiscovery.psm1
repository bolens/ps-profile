<#
scripts/utils/code-quality/modules/FunctionDiscovery.psm1

.SYNOPSIS
    Function discovery utilities.

.DESCRIPTION
    Provides functions for discovering and parsing functions from PowerShell files.
#>

<#
.SYNOPSIS
    Discovers all functions in PowerShell files within a directory.

.DESCRIPTION
    Scans PowerShell files recursively and extracts function definitions, including both
    standard function declarations and functions created via Set-AgentModeFunction.

.PARAMETER Path
    Path to search for PowerShell files.

.PARAMETER RepoRoot
    Repository root path for calculating relative paths.

.OUTPUTS
    Array of PSCustomObject with function information including Name, Verb, Noun, FilePath, etc.
#>
function Get-FunctionsFromPath {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$RepoRoot
    )

    # Import validation functions
    $validatorModule = Join-Path $PSScriptRoot 'FunctionNamingValidator.psm1'
    Import-Module $validatorModule -ErrorAction Stop

    # Try to import FileContent module from scripts/lib (optional)
    $fileContentModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'FileContent.psm1'
    if (Test-Path $fileContentModulePath) {
        Import-Module $fileContentModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }

    $functions = @()
    $profileDFiles = @()
    $scriptFiles = @()

    # Find all PowerShell files
    $psFiles = Get-ChildItem -Path $Path -Recurse -Filter '*.ps1' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notlike '*\node_modules\*' -and $_.FullName -notlike '*\.git\*' }

    foreach ($file in $psFiles) {
        # Use FileContent module if available, otherwise fallback
        if (Get-Command Read-FileContent -ErrorAction SilentlyContinue) {
            $content = Read-FileContent -Path $file.FullName
        }
        else {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        }
        if (-not $content) { continue }

        # Track profile.d files separately
        if ($file.FullName -like '*\profile.d\*') {
            $profileDFiles += $file
        }
        else {
            $scriptFiles += $file
        }

        # Find function definitions
        # Match: function Verb-Noun { or function Verb-Noun(
        $functionMatches = [regex]::Matches($content, '(?m)^\s*function\s+([A-Za-z]+-[A-Za-z0-9_]+)', [System.Text.RegularExpressions.RegexOptions]::Multiline)

        foreach ($match in $functionMatches) {
            $functionName = $match.Groups[1].Value
            $parts = Get-FunctionParts -FunctionName $functionName

            $usesAgentMode = Test-UsesAgentModeFunction -FilePath $file.FullName -FunctionName $functionName

            $functions += [PSCustomObject]@{
                Name                     = $functionName
                Verb                     = $parts.Verb
                Noun                     = $parts.Noun
                IsValidFormat            = $parts.IsValidFormat
                HasApprovedVerb          = if ($parts.Verb) { Test-ApprovedVerb -Verb $parts.Verb } else { $false }
                FilePath                 = $file.FullName
                RelativePath             = $file.FullName.Replace($RepoRoot, '').TrimStart('\', '/')
                IsProfileDFile           = $file.FullName -like '*\profile.d\*'
                UsesSetAgentModeFunction = $usesAgentMode
            }
        }

        # Also find functions created via Set-AgentModeFunction
        $agentModeMatches = [regex]::Matches($content, "Set-AgentModeFunction\s+-Name\s+['`"]([A-Za-z]+-[A-Za-z0-9_]+)['`"]", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

        foreach ($match in $agentModeMatches) {
            $functionName = $match.Groups[1].Value
            $parts = Get-FunctionParts -FunctionName $functionName

            # Check if we already found this function
            if ($functions | Where-Object { $_.Name -eq $functionName -and $_.FilePath -eq $file.FullName }) {
                continue
            }

            $functions += [PSCustomObject]@{
                Name                     = $functionName
                Verb                     = $parts.Verb
                Noun                     = $parts.Noun
                IsValidFormat            = $parts.IsValidFormat
                HasApprovedVerb          = if ($parts.Verb) { Test-ApprovedVerb -Verb $parts.Verb } else { $false }
                FilePath                 = $file.FullName
                RelativePath             = $file.FullName.Replace($RepoRoot, '').TrimStart('\', '/')
                IsProfileDFile           = $file.FullName -like '*\profile.d\*'
                UsesSetAgentModeFunction = $true
            }
        }
    }

    return $functions
}

Export-ModuleMember -Function Get-FunctionsFromPath

                RelativePath             = $file.FullName.Replace($RepoRoot, '').TrimStart('\', '/')
                IsProfileDFile           = $file.FullName -like '*\profile.d\*'
                UsesSetAgentModeFunction = $true
            }
        }
    }

    return $functions
}

Export-ModuleMember -Function Get-FunctionsFromPath

