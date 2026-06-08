<#
scripts/utils/task-parity/modules/TaskParityUtilities.psm1

.SYNOPSIS
    Cross-platform helpers for task-parity parsing and generation.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 5.0+
#>

function Get-TextLineEnding {
    <#
.SYNOPSIS
        Detects the dominant line ending in text content.

.DESCRIPTION
        Detects the dominant line ending in text content.

.PARAMETER Content
        File or help content as text.
.EXAMPLE
    Get-TextLineEnding

#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content
    )

    if ($Content -match "`r`n") {
        return "`r`n"
    }

    if ($Content -match "(?<!`r)`n") {
        return "`n"
    }

    return "`n"
}

function Get-TextFileEncoding {
    <#
.SYNOPSIS
        Returns UTF-8 encoding, preserving BOM when the file already has one.

.DESCRIPTION
        Returns UTF-8 encoding, preserving BOM when the file already has one.

.PARAMETER Path
        File or directory path.
.EXAMPLE
    Get-TextFileEncoding

#>
    [CmdletBinding()]
    [OutputType([System.Text.Encoding])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $encoding = [System.Text.UTF8Encoding]::new($false)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $encoding
    }

    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        $preamble = [System.Text.Encoding]::UTF8.GetPreamble()
        if ($bytes.Length -ge $preamble.Length) {
            $hasBom = $true
            for ($i = 0; $i -lt $preamble.Length; $i++) {
                if ($bytes[$i] -ne $preamble[$i]) {
                    $hasBom = $false
                    break
                }
            }

            if ($hasBom) {
                return [System.Text.UTF8Encoding]::new($true)
            }
        }
    }
    catch {
        Write-Verbose "Could not detect encoding for '$Path': $($_.Exception.Message)"
    }

    return $encoding
}

function Write-TaskParityTextFile {
    <#
.SYNOPSIS
        Writes text using UTF-8 and a stable line ending (preserves existing when known).

.DESCRIPTION
        Writes text using UTF-8 and a stable line ending (preserves existing when known).

.PARAMETER Path
        File or directory path.

.PARAMETER Content
        File or help content as text.

.PARAMETER LineEnding
        Line ending sequence used when writing text.

.PARAMETER ExistingContent
        Original file content used to preserve line endings.
.EXAMPLE
    Write-TaskParityTextFile

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Content,

        [string]$LineEnding = $null,

        [string]$ExistingContent = $null
    )

    if (-not $LineEnding) {
        if ($null -ne $ExistingContent) {
            $LineEnding = Get-TextLineEnding -Content $ExistingContent
        }
        elseif (Test-Path -LiteralPath $Path) {
            $ExistingContent = [System.IO.File]::ReadAllText($Path)
            $LineEnding = Get-TextLineEnding -Content $ExistingContent
        }
        else {
            $LineEnding = "`n"
        }
    }

    $normalizedContent = (($Content -split "`r?`n") -join $LineEnding)
    if (-not $normalizedContent.EndsWith($LineEnding, [System.StringComparison]::Ordinal)) {
        $normalizedContent += $LineEnding
    }

    $encoding = Get-TextFileEncoding -Path $Path
    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($Path, $normalizedContent, $encoding)
}

function Join-TaskCommandLines {
    <#
.SYNOPSIS
        Joins command lines and normalizes script paths for cross-platform comparison.

.DESCRIPTION
        Joins command lines and normalizes script paths for cross-platform comparison.

.PARAMETER Lines
        Text lines to process.
.EXAMPLE
    Join-TaskCommandLines

#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $joined = @(
        $Lines |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { $_.Trim() }
    ) -join "`n"

    if ([string]::IsNullOrWhiteSpace($joined)) {
        return ''
    }

    return Normalize-TaskScriptPathInText -Text $joined
}

function Split-TaskCommandLines {
    <#
.SYNOPSIS
        Splits a multiline task command using CRLF or LF line endings.

.DESCRIPTION
        Splits a multiline task command using CRLF or LF line endings.

.PARAMETER Command
        Shell command text.
.EXAMPLE
    Split-TaskCommandLines

#>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Command
    )

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return @()
    }

    return @(
        $Command -split "`r?`n" |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { $_.Trim() }
    )
}

function Normalize-TaskScriptPathInText {
    <#
.SYNOPSIS
        Normalizes scripts/ path segments to forward slashes for cross-platform commands.

.DESCRIPTION
        Normalizes scripts/ path segments to forward slashes for cross-platform commands.

.PARAMETER Text
        Input text to normalize or inspect.
.EXAMPLE
    Normalize-TaskScriptPathInText

#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Text
    }

    return [regex]::Replace($Text, '(?i)(?<path>(?:\./|\.\./|)?scripts(?:[\\/][^\s"'']+)+)', {
        param($match)
        $match.Groups['path'].Value -replace '\\', '/'
    })
}

function Test-TaskArgumentPlaceholder {
    <#
.SYNOPSIS
        Returns true when a token is a task-runner argument placeholder.

.DESCRIPTION
        Returns true when a token is a task-runner argument placeholder.

.PARAMETER Token
        Token text to evaluate.
.EXAMPLE
    Test-TaskArgumentPlaceholder

#>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Token
    )

    return $Token -match '^\{\{|\}\}$|^\$\(ARGS\)$|^\{\{\.CLI_ARGS\}\}$|^\{\{arguments\(\)\}\}$'
}

function ConvertTo-VsCodeShellTaskDefinition {
    <#
.SYNOPSIS
        Builds a VS Code shell task definition from a reference task command.

.DESCRIPTION
        Builds a VS Code shell task definition from a reference task command.

.PARAMETER Label
        Task label used in tasks.json output.

.PARAMETER Command
        Shell command text.

.PARAMETER Description
        Human-readable task description.
.EXAMPLE
    ConvertTo-VsCodeShellTaskDefinition -InputPath ./input.file

#>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Command,

        [string]$Description = $null
    )

    $trimmed = $Command.Trim()
    $task = @{
        label          = $Label
        type           = 'shell'
        presentation   = @{ reveal = 'always' }
        problemMatcher = @()
    }

    if ($Description) {
        $task.detail = $Description
    }

    if ($trimmed -match '^(?<shellCmd>echo)\s+(?<msg>.+)$') {
        $task.command = $Matches.shellCmd
        $task.args = @($Matches.msg.Trim().Trim('"').Trim("'"))
        return $task
    }

    if ($trimmed -match '^(?<tool>drift)\s+(?<sub>.+)$') {
        $task.command = $Matches.tool
        $task.args = @($Matches.sub.Trim())
        return $task
    }

    if ($trimmed -match '^(?<tool>pnpm|npm)\s+(?<rest>.+)$') {
        $task.command = $Matches.tool
        $task.args = @($Matches.rest.Trim() -split '\s+')
        return $task
    }

    if ($trimmed -match '^(?<tool>task)\s+(?<rest>.+)$') {
        $task.command = $Matches.tool
        $task.args = @($Matches.rest.Trim() -split '\s+')
        return $task
    }

    if ($trimmed -match '^pwsh\b') {
        $pwshParts = ConvertFrom-PwshInvocationCommand -Command $trimmed
        if ($pwshParts) {
            $task.command = $pwshParts.Command
            $task.args = $pwshParts.Args
            return $task
        }
    }

    $parts = $trimmed -split '\s+', 2
    $task.command = $parts[0]
    if ($parts.Count -gt 1 -and -not [string]::IsNullOrWhiteSpace($parts[1])) {
        $task.args = @($parts[1])
    }
    else {
        $task.args = @()
    }

    return $task
}

function ConvertFrom-PwshInvocationCommand {
    <#
.SYNOPSIS
        Parses a pwsh invocation into a VS Code shell command and args array.

.DESCRIPTION
        Parses a pwsh invocation into a VS Code shell command and args array.

.PARAMETER Command
        Shell command text.
.EXAMPLE
    ConvertFrom-PwshInvocationCommand -InputPath ./input.file

#>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    $args = [System.Collections.Generic.List[string]]::new()
    $args.Add('pwsh')

    $remainder = ($Command -replace '^pwsh\s+', '').Trim()

    while ($remainder.Length -gt 0) {
        if ($remainder -match '^\s*-NoProfile\b') {
            $args.Add('-NoProfile')
            $remainder = ($remainder -replace '^\s*-NoProfile\s*', '').TrimStart()
            continue
        }

        if ($remainder -match '^\s*-File\s+(?<path>"[^"]+"|''[^'']+''|[^\s]+)') {
            $path = $Matches.path.Trim().Trim('"').Trim("'")
            $path = Normalize-TaskScriptPathInText -Text $path
            if ($path -notmatch '^\$\{workspaceFolder\}') {
                $path = '${workspaceFolder}/' + ($path -replace '^\.?/', '')
            }

            $args.Add('-File')
            $args.Add($path)
            $remainder = $remainder.Substring($Matches[0].Length).TrimStart()
            continue
        }

        if ($remainder -match '^\s*(?<token>"[^"]+"|''[^'']+''|[^\s]+)') {
            $token = $Matches.token.Trim().Trim('"').Trim("'")
            if (Test-TaskArgumentPlaceholder -Token $token) {
                break
            }

            if ($token.StartsWith('-')) {
                $args.Add($token)
            }
            else {
                $args.Add($token)
            }

            $remainder = $remainder.Substring($Matches[0].Length).TrimStart()
            continue
        }

        break
    }

    return @{
        Command = 'pwsh'
        Args    = $args.ToArray()
    }
}

Export-ModuleMember -Function @(
    'Get-TextLineEnding'
    'Get-TextFileEncoding'
    'Write-TaskParityTextFile'
    'Join-TaskCommandLines'
    'Split-TaskCommandLines'
    'Normalize-TaskScriptPathInText'
    'Test-TaskArgumentPlaceholder'
    'ConvertTo-VsCodeShellTaskDefinition'
    'ConvertFrom-PwshInvocationCommand'
)
