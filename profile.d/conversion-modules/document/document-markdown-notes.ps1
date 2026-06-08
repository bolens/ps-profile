# ===============================================
# Note-app markdown migration tools and transforms
# Joplin, Obsidian, Notion, Logseq helpers
# ===============================================

<#
.SYNOPSIS
    Initializes note-app markdown migration utilities.
.DESCRIPTION
    Placeholder initializer for registry compatibility. Functions in this module
    are registered at load time.
.NOTES
    Internal initialization function; do not call directly.
#>
function Initialize-FileConversion-DocumentMarkdownNotes {
}

<#
.SYNOPSIS
    Converts markdown link syntax to Obsidian wikilinks.
.DESCRIPTION
    Transforms markdown links with relative .md paths into Obsidian wikilinks such as
    [[page|text]] or [[page#anchor|text]]. Skips absolute URLs and non-markdown targets.
.PARAMETER Content
    Markdown content to transform.
.PARAMETER InputPath
    Path to a markdown file to read.
.PARAMETER OutputPath
    Optional path to write transformed content.
.OUTPUTS
    System.String when -PassThru is specified or content is piped.
.EXAMPLE
    ConvertTo-WikilinksFromMarkdownLinks -InputPath ./input.file

#>
function ConvertTo-WikilinksFromMarkdownLinks {
    [CmdletBinding(DefaultParameterSetName = 'Content')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Content', ValueFromPipeline)]
        [string]$Content,

        [Parameter(Mandatory, ParameterSetName = 'File')]
        [string]$InputPath,

        [Parameter(ParameterSetName = 'File')]
        [string]$OutputPath,

        [switch]$PassThru
    )

    process {
        $source = if ($PSCmdlet.ParameterSetName -eq 'File') {
            if (-not (Test-Path -LiteralPath $InputPath)) {
                Write-Error "Input file not found: $InputPath" -ErrorAction Stop
            }
            Get-Content -LiteralPath $InputPath -Raw
        }
        else {
            $Content
        }

        $pattern = '\[(?<text>[^\]]+)\]\((?<target>[^)]+)\)'
        $result = [regex]::Replace($source, $pattern, {
                param($match)
                $text = $match.Groups['text'].Value
                $target = $match.Groups['target'].Value

                if ($target -match '^(https?://|mailto:|#)') {
                    return $match.Value
                }
                if ($target -notmatch '\.(md|markdown)(#|$)|^[^./\\]+$') {
                    return $match.Value
                }

                if ($target -match '^(?<page>[^#]+?)(?:\.md|\.markdown)?(?<anchor>#[^#]+)?$') {
                    $page = $Matches['page']
                    $anchor = $Matches['anchor']
                    $wikiTarget = "$page$anchor"
                    return "[[${wikiTarget}|${text}]]"
                }

                return $match.Value
            })

        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $destination = if ($OutputPath) { $OutputPath } else { $InputPath }
            Set-Content -LiteralPath $destination -Value $result -NoNewline
            if ($PassThru) {
                return $result
            }
        }
        else {
            return $result
        }
    }
}
Set-AgentModeAlias -Name 'md-links-to-wikilinks' -Target 'ConvertTo-WikilinksFromMarkdownLinks'

<#
.SYNOPSIS
    Converts Obsidian wikilinks to standard markdown links.
.DESCRIPTION
    Transforms [[page]], [[page|alias]], and [[page#anchor|alias]] into markdown links.
.PARAMETER Content
    Markdown content to transform.
.PARAMETER InputPath
    Path to a markdown file to read.
.PARAMETER OutputPath
    Optional path to write transformed content.
.OUTPUTS
    System.String when content is piped or -PassThru is used.
.EXAMPLE
    ConvertTo-MarkdownLinksFromWikilinks -InputPath ./input.file

#>
function ConvertTo-MarkdownLinksFromWikilinks {
    [CmdletBinding(DefaultParameterSetName = 'Content')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Content', ValueFromPipeline)]
        [string]$Content,

        [Parameter(Mandatory, ParameterSetName = 'File')]
        [string]$InputPath,

        [Parameter(ParameterSetName = 'File')]
        [string]$OutputPath,

        [switch]$PassThru,

        [switch]$AddMdExtension
    )

    process {
        $source = if ($PSCmdlet.ParameterSetName -eq 'File') {
            if (-not (Test-Path -LiteralPath $InputPath)) {
                Write-Error "Input file not found: $InputPath" -ErrorAction Stop
            }
            Get-Content -LiteralPath $InputPath -Raw
        }
        else {
            $Content
        }

        $pattern = '\[\[(?<target>[^\]|#]+(?:#[^\]|]+)?)(?:\|(?<alias>[^\]]+))?\]\]'
        $result = [regex]::Replace($source, $pattern, {
                param($match)
                $target = $match.Groups['target'].Value
                $alias = $match.Groups['alias'].Value

                if ($AddMdExtension -and $target -notmatch '\.(md|markdown)(#|$)' -and $target -notmatch '#') {
                    $target = "$target.md"
                }
                elseif ($AddMdExtension -and $target -match '^(?<page>[^#]+)(?<anchor>#.+)$') {
                    $target = "$($Matches['page']).md$($Matches['anchor'])"
                }

                $label = if ($alias) { $alias } else { ($target -replace '\.md$', '') -replace '#.*$', '' }
                return "[$label]($target)"
            })

        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $destination = if ($OutputPath) { $OutputPath } else { $InputPath }
            Set-Content -LiteralPath $destination -Value $result -NoNewline
            if ($PassThru) {
                return $result
            }
        }
        else {
            return $result
        }
    }
}
Set-AgentModeAlias -Name 'wikilinks-to-md-links' -Target 'ConvertTo-MarkdownLinksFromWikilinks'

<#
.SYNOPSIS
    Converts Logseq property lines to YAML front matter.
.DESCRIPTION
    Moves leading key:: value lines (Logseq page properties) into a YAML front
    matter block at the top of the document.
.PARAMETER Content
    Markdown content to transform.
.PARAMETER InputPath
    Path to a markdown file to read.
.PARAMETER OutputPath
    Optional path to write transformed content.
.OUTPUTS
    System.String when content is piped or -PassThru is used.
.EXAMPLE
    Convert-LogseqPropertiesToYamlFrontMatter

#>
function Convert-LogseqPropertiesToYamlFrontMatter {
    [CmdletBinding(DefaultParameterSetName = 'Content')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Content', ValueFromPipeline)]
        [string]$Content,

        [Parameter(Mandatory, ParameterSetName = 'File')]
        [string]$InputPath,

        [Parameter(ParameterSetName = 'File')]
        [string]$OutputPath,

        [switch]$PassThru
    )

    process {
        $source = if ($PSCmdlet.ParameterSetName -eq 'File') {
            if (-not (Test-Path -LiteralPath $InputPath)) {
                Write-Error "Input file not found: $InputPath" -ErrorAction Stop
            }
            Get-Content -LiteralPath $InputPath -Raw
        }
        else {
            $Content
        }

        $lines = $source -split '\r?\n'
        $properties = [ordered]@{}
        $bodyStart = 0

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ([string]::IsNullOrWhiteSpace($line)) {
                if ($properties.Count -gt 0) {
                    $bodyStart = $i + 1
                    break
                }
                continue
            }

            if ($line -match '^(?<key>[^\s:]+)::\s*(?<value>.+)$') {
                $properties[$Matches['key'].Trim()] = $Matches['value'].Trim()
                $bodyStart = $i + 1
                continue
            }

            if ($properties.Count -gt 0) {
                break
            }

            $bodyStart = $i
            break
        }

        if ($properties.Count -eq 0) {
            $result = $source
        }
        else {
            $yamlLines = foreach ($key in $properties.Keys) {
                $value = $properties[$key]
                if ($value -match '[\:\#\[\]\{\}&,]' -or $value.StartsWith('#')) {
                    $escaped = $value -replace '"', '\"'
                    "${key}: `"${escaped}`""
                }
                else {
                    "${key}: $value"
                }
            }

            $body = ($lines[$bodyStart..($lines.Count - 1)] -join "`n").TrimStart("`n")
            $result = "---`n$($yamlLines -join "`n")`n---`n$body"
        }

        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $destination = if ($OutputPath) { $OutputPath } else { $InputPath }
            Set-Content -LiteralPath $destination -Value $result -NoNewline
            if ($PassThru) {
                return $result
            }
        }
        else {
            return $result
        }
    }
}
Set-AgentModeAlias -Name 'logseq-to-yaml' -Target 'Convert-LogseqPropertiesToYamlFrontMatter'

<#
.SYNOPSIS
    Rewrites Joplin resource links to local attachment paths.
.DESCRIPTION
    Converts Joplin-style resource references (![](:/resourceId)) to standard
    markdown image links using a resource map or a _resources directory lookup.
.PARAMETER Content
    Markdown content to transform.
.PARAMETER InputPath
    Path to a markdown file to read.
.PARAMETER OutputPath
    Optional path to write transformed content.
.PARAMETER ResourceMap
    Hashtable mapping Joplin resource IDs to relative file paths.
.PARAMETER ResourcesDirectory
    Directory containing exported Joplin resources (matches by filename prefix).
.OUTPUTS
    System.String when content is piped or -PassThru is used.
.EXAMPLE
    Convert-JoplinResourceLinksToLocal

#>
function Convert-JoplinResourceLinksToLocal {
    [CmdletBinding(DefaultParameterSetName = 'Content')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Content', ValueFromPipeline)]
        [string]$Content,

        [Parameter(Mandatory, ParameterSetName = 'File')]
        [string]$InputPath,

        [Parameter(ParameterSetName = 'File')]
        [string]$OutputPath,

        [hashtable]$ResourceMap,

        [string]$ResourcesDirectory = '_resources',

        [switch]$PassThru
    )

    process {
        $source = if ($PSCmdlet.ParameterSetName -eq 'File') {
            if (-not (Test-Path -LiteralPath $InputPath)) {
                Write-Error "Input file not found: $InputPath" -ErrorAction Stop
            }
            Get-Content -LiteralPath $InputPath -Raw
        }
        else {
            $Content
        }

        $resourceLookup = @{}
        if ($ResourceMap) {
            foreach ($entry in $ResourceMap.GetEnumerator()) {
                $resourceLookup[$entry.Key] = $entry.Value
            }
        }

        $pattern = '!\[(?<alt>[^\]]*)\]\(:(?<id>[a-fA-F0-9]{32})\)'
        $result = [regex]::Replace($source, $pattern, {
                param($match)
                $alt = $match.Groups['alt'].Value
                $id = $match.Groups['id'].Value.ToLowerInvariant()

                $relativePath = $null
                if ($resourceLookup.ContainsKey($id)) {
                    $relativePath = $resourceLookup[$id]
                }
                elseif ($ResourcesDirectory -and (Test-Path -LiteralPath $ResourcesDirectory)) {
                    $file = Get-ChildItem -LiteralPath $ResourcesDirectory -File -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name.ToLowerInvariant().StartsWith($id) } |
                        Select-Object -First 1
                    if ($file) {
                        $relativePath = Join-Path $ResourcesDirectory $file.Name
                    }
                }

                if ($relativePath) {
                    return "![${alt}](${relativePath})"
                }

                return $match.Value
            })

        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $destination = if ($OutputPath) { $OutputPath } else { $InputPath }
            Set-Content -LiteralPath $destination -Value $result -NoNewline
            if ($PassThru) {
                return $result
            }
        }
        else {
            return $result
        }
    }
}
Set-AgentModeAlias -Name 'joplin-links-to-local' -Target 'Convert-JoplinResourceLinksToLocal'

<#
.SYNOPSIS
    Converts Notion-style callout blockquotes to Obsidian callout syntax.
.DESCRIPTION
    Rewrites blockquotes such as "> **Note**" or "> 💡 Tip" into Obsidian
    callouts like "> [!NOTE]" and "> [!TIP]".
.PARAMETER Content
    Markdown content to transform.
.PARAMETER InputPath
    Path to a markdown file to read.
.PARAMETER OutputPath
    Optional path to write transformed content.
.OUTPUTS
    System.String when content is piped or -PassThru is used.
.EXAMPLE
    Convert-NotionCalloutsToObsidian

#>
function Convert-NotionCalloutsToObsidian {
    [CmdletBinding(DefaultParameterSetName = 'Content')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Content', ValueFromPipeline)]
        [string]$Content,

        [Parameter(Mandatory, ParameterSetName = 'File')]
        [string]$InputPath,

        [Parameter(ParameterSetName = 'File')]
        [string]$OutputPath,

        [switch]$PassThru
    )

    process {
        $source = if ($PSCmdlet.ParameterSetName -eq 'File') {
            if (-not (Test-Path -LiteralPath $InputPath)) {
                Write-Error "Input file not found: $InputPath" -ErrorAction Stop
            }
            Get-Content -LiteralPath $InputPath -Raw
        }
        else {
            $Content
        }

        $calloutMap = [ordered]@{
            'note'     = 'NOTE'
            'info'     = 'INFO'
            'tip'      = 'TIP'
            'important' = 'IMPORTANT'
            'warning'  = 'WARNING'
            'caution'  = 'CAUTION'
            'success'  = 'SUCCESS'
            'question' = 'QUESTION'
            'quote'    = 'QUOTE'
            'abstract' = 'ABSTRACT'
            'example'  = 'EXAMPLE'
        }

        $emojiMap = @{
            '💡' = 'TIP'
            'ℹ️' = 'INFO'
            'ℹ'  = 'INFO'
            '⚠️' = 'WARNING'
            '⚠'  = 'WARNING'
            '❗' = 'IMPORTANT'
            '✅' = 'SUCCESS'
            '❓' = 'QUESTION'
        }

        $lines = $source -split '\r?\n'
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line -notmatch '^>\s*(?<body>.+)$') {
                continue
            }

            $body = $Matches['body'].Trim()
            $calloutType = $null

            if ($body -match '^\*\*(?<label>[A-Za-z ]+)\*\*(?<rest>.*)$') {
                $labelKey = $Matches['label'].Trim().ToLowerInvariant()
                if ($calloutMap.Contains($labelKey)) {
                    $calloutType = $calloutMap[$labelKey]
                    $rest = $Matches['rest'].Trim()
                    $lines[$i] = if ($rest) { "> [!${calloutType}] $rest" } else { "> [!${calloutType}]" }
                    continue
                }
            }

            foreach ($emoji in $emojiMap.Keys) {
                if ($body.StartsWith($emoji)) {
                    $calloutType = $emojiMap[$emoji]
                    $rest = $body.Substring($emoji.Length).Trim()
                    $lines[$i] = if ($rest) { "> [!${calloutType}] $rest" } else { "> [!${calloutType}]" }
                    break
                }
            }
        }

        $result = $lines -join "`n"

        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $destination = if ($OutputPath) { $OutputPath } else { $InputPath }
            Set-Content -LiteralPath $destination -Value $result -NoNewline
            if ($PassThru) {
                return $result
            }
        }
        else {
            return $result
        }
    }
}
Set-AgentModeAlias -Name 'notion-callouts-to-obsidian' -Target 'Convert-NotionCalloutsToObsidian'

<#
.SYNOPSIS
    Reorganizes a Joplin markdown export for Obsidian vault import.
.DESCRIPTION
    Moves attachments from a global _resources folder into per-note _resources
    directories and cleans trailing underscores from filenames.
.PARAMETER ExportDirectory
    Root directory of a Joplin "Markdown + Front Matter" export.
.PARAMETER WhatIf
    Preview changes without moving files.
.OUTPUTS
    PSCustomObject summary with MovedResources and UpdatedFiles counts.
.EXAMPLE
    Convert-JoplinExportForObsidian

#>
function Convert-JoplinExportForObsidian {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ExportDirectory
    )

    if (-not (Test-Path -LiteralPath $ExportDirectory)) {
        Write-Error "Export directory not found: $ExportDirectory" -ErrorAction Stop
    }

    $globalResources = Join-Path $ExportDirectory '_resources'
    $moved = 0
    $updated = 0

    $markdownFiles = Get-ChildItem -LiteralPath $ExportDirectory -Filter '*.md' -File -Recurse
    foreach ($mdFile in $markdownFiles) {
        $content = Get-Content -LiteralPath $mdFile.FullName -Raw
        $refs = [regex]::Matches($content, '\((?<path>_resources/[^)]+)\)')
        if ($refs.Count -eq 0) {
            continue
        }

        $noteResourcesDir = Join-Path $mdFile.DirectoryName '_resources'
        $changed = $false

        foreach ($refMatch in $refs) {
            $relativePath = $refMatch.Groups['path'].Value
            $fileName = Split-Path $relativePath -Leaf
            $cleanName = $fileName.TrimEnd('_', ' ')
            $sourcePath = Join-Path $globalResources $fileName

            if (-not (Test-Path -LiteralPath $sourcePath)) {
                $sourcePath = Join-Path $globalResources $cleanName
            }

            if (-not (Test-Path -LiteralPath $sourcePath)) {
                continue
            }

            if (-not (Test-Path -LiteralPath $noteResourcesDir)) {
                if ($PSCmdlet.ShouldProcess($noteResourcesDir, 'Create directory')) {
                    New-Item -ItemType Directory -Path $noteResourcesDir -Force | Out-Null
                }
            }

            $destPath = Join-Path $noteResourcesDir $cleanName
            if ($PSCmdlet.ShouldProcess($sourcePath, "Move to $destPath")) {
                if (-not $WhatIfPreference) {
                    Move-Item -LiteralPath $sourcePath -Destination $destPath -Force -ErrorAction SilentlyContinue
                }
                $moved++
            }

            if ($fileName -ne $cleanName) {
                $newRelative = "_resources/$cleanName"
                $content = $content.Replace($relativePath, $newRelative)
                $changed = $true
            }
        }

        if ($changed -and $PSCmdlet.ShouldProcess($mdFile.FullName, 'Update resource links')) {
            if (-not $WhatIfPreference) {
                Set-Content -LiteralPath $mdFile.FullName -Value $content -NoNewline
            }
            $updated++
        }
    }

    [pscustomobject]@{
        ExportDirectory = $ExportDirectory
        MovedResources  = $moved
        UpdatedFiles    = $updated
    }
}
Set-AgentModeAlias -Name 'joplin-export-to-obsidian' -Target 'Convert-JoplinExportForObsidian'

<#
.SYNOPSIS
    Exports a Notion page to markdown using notion2md or notionify-cli.
.DESCRIPTION
    Wraps available Notion export CLIs. Requires NOTION_TOKEN or -Token.
.PARAMETER Url
    Notion page URL or page ID.
.PARAMETER OutputPath
    Output directory or file path for exported markdown.
.PARAMETER Token
    Notion integration token. Defaults to $env:NOTION_TOKEN.
.PARAMETER DownloadAssets
    Download images and attachments when supported by the CLI.
.OUTPUTS
    None. Writes files via the underlying CLI.
.EXAMPLE
    Export-NotionPageToMarkdown

#>
function Export-NotionPageToMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [string]$OutputPath,

        [string]$Token,

        [switch]$DownloadAssets
    )

    $notionToken = if ($Token) { $Token } else { $env:NOTION_TOKEN }

    if (Test-CachedCommand 'notion2md') {
        $args = @('-u', $Url)
        if ($notionToken) {
            $args += @('-t', $notionToken)
        }
        if ($OutputPath) {
            $outputDir = if (Test-Path -LiteralPath $OutputPath -PathType Container) {
                $OutputPath
            }
            else {
                Split-Path -Parent $OutputPath
            }
            if ($outputDir) {
                $args += @('-p', $outputDir)
            }
        }
        if ($DownloadAssets) {
            $args += '--download'
        }

        & notion2md @args
        if ($LASTEXITCODE -ne 0) {
            Write-Error "notion2md failed with exit code $LASTEXITCODE"
        }
        return
    }

    if (Test-CachedCommand 'notionify-cli') {
        if (-not $notionToken) {
            Write-Error 'Notion token required. Set NOTION_TOKEN or pass -Token.' -ErrorAction Stop
        }

        $pageId = $Url
        if ($Url -match '[0-9a-f]{32}|([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
            $pageId = $Matches[0] -replace '-', ''
        }

        $args = @('pull', $pageId)
        if ($OutputPath) {
            $args += @('--out', $OutputPath)
        }

        $previousToken = $env:NOTION_TOKEN
        $env:NOTION_TOKEN = $notionToken
        try {
            & notionify-cli @args
            if ($LASTEXITCODE -ne 0) {
                Write-Error "notionify-cli failed with exit code $LASTEXITCODE"
            }
        }
        finally {
            if ($null -ne $previousToken) {
                $env:NOTION_TOKEN = $previousToken
            }
            else {
                Remove-Item Env:NOTION_TOKEN -ErrorAction SilentlyContinue
            }
        }
        return
    }

    if (Test-CachedCommand 'notion2markdown') {
        if (-not $notionToken) {
            Write-Error 'Notion token required. Set NOTION_TOKEN or pass -Token.' -ErrorAction Stop
        }

        $previousToken = $env:NOTION_TOKEN
        $env:NOTION_TOKEN = $notionToken
        try {
            if ($OutputPath -and (Test-Path -LiteralPath $OutputPath -PathType Container)) {
                Push-Location $OutputPath
                try {
                    & notion2markdown $Url
                }
                finally {
                    Pop-Location
                }
            }
            else {
                & notion2markdown $Url
            }

            if ($LASTEXITCODE -ne 0) {
                Write-Error "notion2markdown failed with exit code $LASTEXITCODE"
            }
        }
        finally {
            if ($null -ne $previousToken) {
                $env:NOTION_TOKEN = $previousToken
            }
            else {
                Remove-Item Env:NOTION_TOKEN -ErrorAction SilentlyContinue
            }
        }
        return
    }

    $installHint = 'pip install notion2md  # or: pip install notionify / pip install notion2markdown'
    if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
        Write-MissingToolWarning -Tool 'notion2md' -InstallHint $installHint
    }
    Write-Error "No Notion export CLI found. Install with: $installHint" -ErrorAction Stop
}
Set-AgentModeAlias -Name 'notion-to-markdown' -Target 'Export-NotionPageToMarkdown'

<#
.SYNOPSIS
    Invokes notionify-cli with standard argument forwarding.
.DESCRIPTION
    Wrapper for notionify-cli convert/push/pull/sync commands.
.PARAMETER Command
    notionify-cli subcommand (convert, push, pull, sync).
.PARAMETER Arguments
    Additional arguments forwarded to notionify-cli.
.OUTPUTS
    CLI output from notionify-cli.
.EXAMPLE
    Invoke-NotionifyCli

#>
function Invoke-NotionifyCli {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('convert', 'push', 'pull', 'sync')]
        [string]$Command,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    if (-not (Test-CachedCommand 'notionify-cli')) {
        $installHint = 'pip install notionify'
        if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
            Write-MissingToolWarning -Tool 'notionify-cli' -InstallHint $installHint
        }
        Write-Error "notionify-cli not found. Install with: $installHint" -ErrorAction Stop
    }

    $cliArgs = @($Command) + @($Arguments)
    & notionify-cli @cliArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "notionify-cli failed with exit code $LASTEXITCODE"
    }
}
Set-AgentModeAlias -Name 'notionify' -Target 'Invoke-NotionifyCli'

<#
.SYNOPSIS
    Synchronizes notes between Joplin and Obsidian using joplin-obsidian-bridge.
.DESCRIPTION
    Wraps the job CLI from joplin-obsidian-bridge. Use -Preview to dry-run sync.
.PARAMETER Force
    Execute sync (without this flag, job performs a preview/dry-run).
.PARAMETER JoplinToObsidian
    Sync only from Joplin to Obsidian.
.PARAMETER ObsidianToJoplin
    Sync only from Obsidian to Joplin.
.PARAMETER Manual
    Use interactive confirmation mode (sync-manual).
.PARAMETER Arguments
    Additional arguments forwarded to job.
.OUTPUTS
    CLI output from job.
.EXAMPLE
    Sync-JoplinObsidianNotes

#>
function Sync-JoplinObsidianNotes {
    [CmdletBinding()]
    param(
        [switch]$Force,

        [switch]$JoplinToObsidian,

        [switch]$ObsidianToJoplin,

        [switch]$Manual,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    if (-not (Test-CachedCommand 'job')) {
        $installHint = 'pip install joplin-obsidian-bridge'
        if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
            Write-MissingToolWarning -Tool 'job' -InstallHint $installHint
        }
        Write-Error "job CLI not found. Install with: $installHint" -ErrorAction Stop
    }

    $subCommand = if ($Manual) { 'sync-manual' } else { 'sync' }
    $jobArgs = @($subCommand)

    if ($Force) {
        $jobArgs += '--force'
    }
    if ($JoplinToObsidian) {
        $jobArgs += '--joplin-to-obsidian'
    }
    if ($ObsidianToJoplin) {
        $jobArgs += '--obsidian-to-joplin'
    }
    if ($Arguments) {
        $jobArgs += $Arguments
    }

    & job @jobArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "job sync failed with exit code $LASTEXITCODE"
    }
}
Set-AgentModeAlias -Name 'joplin-obsidian-sync' -Target 'Sync-JoplinObsidianNotes'
