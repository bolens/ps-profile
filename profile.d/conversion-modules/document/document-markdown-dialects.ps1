# ===============================================
# Markdown dialect and wiki markup conversion utilities
# GFM, CommonMark, Obsidian-flavored MD, MultiMarkdown, wiki formats
# ===============================================

<#
.SYNOPSIS
    Resolves a markdown dialect alias to a pandoc reader/writer format string.
.DESCRIPTION
    Maps friendly dialect names (gfm, obsidian, multimarkdown, etc.) to pandoc
    format identifiers, including Obsidian-specific extension bundles.
.PARAMETER Dialect
    Dialect alias or pandoc format name.
.PARAMETER ForOutput
    When set, returns the writer-oriented format (e.g. Obsidian export uses gfm+wikilinks).
.OUTPUTS
    System.String
.EXAMPLE
    Get-MarkdownDialectPandocFormat -Dialect obsidian -ForOutput
#>
function Get-MarkdownDialectPandocFormat {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Dialect,

        [switch]$ForOutput
    )

    $key = $Dialect.Trim().ToLowerInvariant()

    $inputFormats = @{
        'commonmark'         = 'commonmark'
        'commonmark_x'       = 'commonmark_x'
        'gfm'                = 'gfm'
        'github'             = 'gfm'
        'markdown'           = 'markdown'
        'pandoc'             = 'markdown'
        'multimarkdown'      = 'markdown_mmd'
        'mmd'                = 'markdown_mmd'
        'markdown_mmd'       = 'markdown_mmd'
        'phpextra'           = 'markdown_phpextra'
        'markdown_phpextra'  = 'markdown_phpextra'
        'strict'             = 'markdown_strict'
        'markdown_strict'    = 'markdown_strict'
        'obsidian'           = 'markdown+wikilinks_title_after_pipe+mark+task_lists'
        'obsidian_gfm'       = 'gfm+wikilinks_title_after_pipe+mark+task_lists'
    }

    $outputFormats = @{
        'commonmark'         = 'commonmark'
        'commonmark_x'       = 'commonmark_x'
        'gfm'                = 'gfm'
        'github'             = 'gfm'
        'markdown'           = 'markdown'
        'pandoc'             = 'markdown'
        'multimarkdown'      = 'markdown_mmd'
        'mmd'                = 'markdown_mmd'
        'markdown_mmd'       = 'markdown_mmd'
        'phpextra'           = 'markdown_phpextra'
        'markdown_phpextra'  = 'markdown_phpextra'
        'strict'             = 'markdown_strict'
        'markdown_strict'    = 'markdown_strict'
        'obsidian'           = 'gfm+wikilinks_title_after_pipe'
        'obsidian_gfm'       = 'gfm+wikilinks_title_after_pipe'
    }

    $map = if ($ForOutput) { $outputFormats } else { $inputFormats }

    if ($map.ContainsKey($key)) {
        return $map[$key]
    }

    return $Dialect
}

<#
.SYNOPSIS
    Initializes markdown dialect conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for markdown dialect and wiki markup
    conversions via pandoc. Called automatically by Ensure-FileConversion-Documents.
.NOTES
    Internal initialization function; do not call directly.
#>
function Initialize-FileConversion-DocumentMarkdownDialects {
    Set-Item -Path Function:Global:_Invoke-PandocMarkdownConversion -Value {
        param(
            [string]$InputPath,
            [string]$OutputPath,
            [string]$FromFormat,
            [string]$ToFormat,
            [string]$DefaultOutputExtension,
            [string]$ErrorLabel
        )

        if (-not $InputPath) {
            throw 'InputPath parameter is required'
        }
        if (-not (Test-Path -LiteralPath $InputPath)) {
            throw "Input file not found: $InputPath"
        }
        if (-not (Test-CachedCommand 'pandoc')) {
            throw 'pandoc command not found. Please install pandoc to use this conversion function.'
        }

        if (-not $OutputPath) {
            $OutputPath = $InputPath -replace '\.[^.\\/]+$', $DefaultOutputExtension
        }

        $errorOutput = & pandoc -f $FromFormat -t $ToFormat $InputPath -o $OutputPath 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            $errorText = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { 'Unknown error' }
            throw "pandoc failed with exit code $exitCode when converting $ErrorLabel. Error: $errorText"
        }
    } -Force

    Set-Item -Path Function:Global:_Convert-MarkdownDialect -Value {
        param(
            [string]$InputPath,
            [string]$OutputPath,
            [string]$From,
            [string]$To
        )

        try {
            $fromFormat = Get-MarkdownDialectPandocFormat -Dialect $From
            $toFormat = Get-MarkdownDialectPandocFormat -Dialect $To -ForOutput
            $label = "$From markdown to $To markdown"

            _Invoke-PandocMarkdownConversion -InputPath $InputPath -OutputPath $OutputPath `
                -FromFormat $fromFormat -ToFormat $toFormat -DefaultOutputExtension '.md' -ErrorLabel $label
        }
        catch {
            Write-Error "Failed to convert markdown dialect ($From -> $To): $($_.Exception.Message)"
            throw
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-WikiMarkupToMarkdown -Value {
        param(
            [string]$InputPath,
            [string]$OutputPath,
            [string]$WikiFormat,
            [string]$TargetDialect,
            [string]$InputExtensionPattern,
            [string]$ErrorLabel
        )

        try {
            $toFormat = Get-MarkdownDialectPandocFormat -Dialect $TargetDialect -ForOutput

            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace $InputExtensionPattern, '.md'
            }

            _Invoke-PandocMarkdownConversion -InputPath $InputPath -OutputPath $OutputPath `
                -FromFormat $WikiFormat -ToFormat $toFormat -DefaultOutputExtension '.md' -ErrorLabel $ErrorLabel
        }
        catch {
            Write-Error "Failed to convert $ErrorLabel`: $($_.Exception.Message)"
            throw
        }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-WikiMarkupFromMarkdown -Value {
        param(
            [string]$InputPath,
            [string]$OutputPath,
            [string]$WikiFormat,
            [string]$SourceDialect,
            [string]$OutputExtension,
            [string]$ErrorLabel
        )

        try {
            $fromFormat = Get-MarkdownDialectPandocFormat -Dialect $SourceDialect

            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(md|markdown)$', $OutputExtension
            }

            _Invoke-PandocMarkdownConversion -InputPath $InputPath -OutputPath $OutputPath `
                -FromFormat $fromFormat -ToFormat $WikiFormat -DefaultOutputExtension $OutputExtension -ErrorLabel $ErrorLabel
        }
        catch {
            Write-Error "Failed to convert $ErrorLabel`: $($_.Exception.Message)"
            throw
        }
    } -Force
}

<#
.SYNOPSIS
    Converts markdown between dialects using pandoc.

.DESCRIPTION
    Internal dispatcher used by Convert-MarkdownDialect aliases. Loads document
    conversion helpers when needed and forwards to _Convert-MarkdownDialect.

.PARAMETER InputPath
    Path to the input markdown file.

.PARAMETER OutputPath
    Optional output path. Defaults to the input path with .md extension.

.PARAMETER From
    Source dialect alias or pandoc reader format.

.PARAMETER To
    Target dialect alias or pandoc writer format.

.EXAMPLE
    Invoke-MarkdownDialectConversion -InputPath note.md -From obsidian -To gfm
#>
function Invoke-MarkdownDialectConversion {
    [CmdletBinding()]
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [Parameter(Mandatory)]
        [string]$From,
        [Parameter(Mandatory)]
        [string]$To
    )

    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    if (Get-Command _Convert-MarkdownDialect -ErrorAction SilentlyContinue) {
        _Convert-MarkdownDialect @PSBoundParameters
    }
    else {
        Write-Error 'Internal conversion function _Convert-MarkdownDialect not available' -ErrorAction Stop
    }
}
Set-AgentModeAlias -Name 'convert-markdown-dialect' -Target 'Invoke-MarkdownDialectConversion'

<#
.SYNOPSIS
    Converts markdown between dialects/standards using pandoc.
.DESCRIPTION
    Converts a markdown file from one dialect to another. Supports CommonMark, GFM,
    Pandoc markdown, MultiMarkdown, PHP Markdown Extra, strict markdown, and
    Obsidian-flavored markdown (wikilinks, highlights, task lists).
.PARAMETER InputPath
    Path to the input markdown file.
.PARAMETER OutputPath
    Optional output path. Defaults to the input path with .md extension.
.PARAMETER From
    Source dialect (commonmark, gfm, obsidian, multimarkdown, phpextra, strict, markdown).
.PARAMETER To
    Target dialect.
.EXAMPLE
    Convert-MarkdownDialect -InputPath note.md -From obsidian -To gfm
#>
function Convert-MarkdownDialect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$InputPath,
        [string]$OutputPath,
        [Parameter(Mandatory)]
        [string]$From,
        [Parameter(Mandatory)]
        [string]$To
    )

    Invoke-MarkdownDialectConversion @PSBoundParameters
}
Set-AgentModeAlias -Name 'markdown-dialect' -Target 'Convert-MarkdownDialect'

function ConvertFrom-GfmToCommonmark {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$InputPath, [string]$OutputPath)
    Convert-MarkdownDialect -InputPath $InputPath -OutputPath $OutputPath -From gfm -To commonmark
}
Set-AgentModeAlias -Name 'gfm-to-commonmark' -Target 'ConvertFrom-GfmToCommonmark'

function ConvertTo-GfmFromCommonmark {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$InputPath, [string]$OutputPath)
    Convert-MarkdownDialect -InputPath $InputPath -OutputPath $OutputPath -From commonmark -To gfm
}
Set-AgentModeAlias -Name 'commonmark-to-gfm' -Target 'ConvertTo-GfmFromCommonmark'

function ConvertFrom-ObsidianMarkdownToGfm {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$InputPath, [string]$OutputPath)
    Convert-MarkdownDialect -InputPath $InputPath -OutputPath $OutputPath -From obsidian -To gfm
}
Set-AgentModeAlias -Name 'obsidian-to-gfm' -Target 'ConvertFrom-ObsidianMarkdownToGfm'

function ConvertTo-ObsidianMarkdownFromGfm {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$InputPath, [string]$OutputPath)
    Convert-MarkdownDialect -InputPath $InputPath -OutputPath $OutputPath -From gfm -To obsidian
}
Set-AgentModeAlias -Name 'gfm-to-obsidian' -Target 'ConvertTo-ObsidianMarkdownFromGfm'

function ConvertFrom-MultiMarkdownToGfm {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$InputPath, [string]$OutputPath)
    Convert-MarkdownDialect -InputPath $InputPath -OutputPath $OutputPath -From multimarkdown -To gfm
}
Set-AgentModeAlias -Name 'multimarkdown-to-gfm' -Target 'ConvertFrom-MultiMarkdownToGfm'

function ConvertTo-MultiMarkdownFromGfm {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$InputPath, [string]$OutputPath)
    Convert-MarkdownDialect -InputPath $InputPath -OutputPath $OutputPath -From gfm -To multimarkdown
}
Set-AgentModeAlias -Name 'gfm-to-multimarkdown' -Target 'ConvertTo-MultiMarkdownFromGfm'

function ConvertFrom-PhpMarkdownExtraToGfm {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$InputPath, [string]$OutputPath)
    Convert-MarkdownDialect -InputPath $InputPath -OutputPath $OutputPath -From phpextra -To gfm
}
Set-AgentModeAlias -Name 'phpextra-to-gfm' -Target 'ConvertFrom-PhpMarkdownExtraToGfm'

function ConvertFrom-MarkdownStrictToGfm {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$InputPath, [string]$OutputPath)
    Convert-MarkdownDialect -InputPath $InputPath -OutputPath $OutputPath -From strict -To gfm
}
Set-AgentModeAlias -Name 'strict-to-gfm' -Target 'ConvertFrom-MarkdownStrictToGfm'

function ConvertFrom-MediawikiToMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InputPath,
        [string]$OutputPath,
        [string]$TargetDialect = 'gfm'
    )

    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-WikiMarkupToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-WikiMarkupToMarkdown -InputPath $InputPath -OutputPath $OutputPath `
                -WikiFormat 'mediawiki' -TargetDialect $TargetDialect `
                -InputExtensionPattern '\.(wiki|mediawiki)$' -ErrorLabel 'MediaWiki to Markdown'
        }
        else {
            Write-Error 'Internal conversion function _ConvertFrom-WikiMarkupToMarkdown not available' -ErrorAction Stop
        }
    }
    catch {
        Write-Error "Failed to convert MediaWiki to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
Set-AgentModeAlias -Name 'mediawiki-to-markdown' -Target 'ConvertFrom-MediawikiToMarkdown'

function ConvertFrom-DokuwikiToMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InputPath,
        [string]$OutputPath,
        [string]$TargetDialect = 'gfm'
    )

    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-WikiMarkupToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-WikiMarkupToMarkdown -InputPath $InputPath -OutputPath $OutputPath `
                -WikiFormat 'dokuwiki' -TargetDialect $TargetDialect `
                -InputExtensionPattern '\.(dokuwiki|doku|txt)$' -ErrorLabel 'DokuWiki to Markdown'
        }
        else {
            Write-Error 'Internal conversion function _ConvertFrom-WikiMarkupToMarkdown not available' -ErrorAction Stop
        }
    }
    catch {
        Write-Error "Failed to convert DokuWiki to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
Set-AgentModeAlias -Name 'dokuwiki-to-markdown' -Target 'ConvertFrom-DokuwikiToMarkdown'

function ConvertFrom-JiraToMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InputPath,
        [string]$OutputPath,
        [string]$TargetDialect = 'gfm'
    )

    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertFrom-WikiMarkupToMarkdown -ErrorAction SilentlyContinue) {
            _ConvertFrom-WikiMarkupToMarkdown -InputPath $InputPath -OutputPath $OutputPath `
                -WikiFormat 'jira' -TargetDialect $TargetDialect `
                -InputExtensionPattern '\.(jira|confluence)$' -ErrorLabel 'Jira/Confluence to Markdown'
        }
        else {
            Write-Error 'Internal conversion function _ConvertFrom-WikiMarkupToMarkdown not available' -ErrorAction Stop
        }
    }
    catch {
        Write-Error "Failed to convert Jira/Confluence to Markdown: $_" -ErrorAction SilentlyContinue
    }
}
Set-AgentModeAlias -Name 'jira-to-markdown' -Target 'ConvertFrom-JiraToMarkdown'
Set-AgentModeAlias -Name 'confluence-to-markdown' -Target 'ConvertFrom-JiraToMarkdown'

function ConvertTo-MediawikiFromMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InputPath,
        [string]$OutputPath,
        [string]$SourceDialect = 'gfm'
    )

    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-WikiMarkupFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-WikiMarkupFromMarkdown -InputPath $InputPath -OutputPath $OutputPath `
                -WikiFormat 'mediawiki' -SourceDialect $SourceDialect -OutputExtension '.wiki' `
                -ErrorLabel 'Markdown to MediaWiki'
        }
        else {
            Write-Error 'Internal conversion function _ConvertTo-WikiMarkupFromMarkdown not available' -ErrorAction Stop
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to MediaWiki: $_" -ErrorAction SilentlyContinue
    }
}
Set-AgentModeAlias -Name 'markdown-to-mediawiki' -Target 'ConvertTo-MediawikiFromMarkdown'

function ConvertTo-DokuwikiFromMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InputPath,
        [string]$OutputPath,
        [string]$SourceDialect = 'gfm'
    )

    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-WikiMarkupFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-WikiMarkupFromMarkdown -InputPath $InputPath -OutputPath $OutputPath `
                -WikiFormat 'dokuwiki' -SourceDialect $SourceDialect -OutputExtension '.dokuwiki' `
                -ErrorLabel 'Markdown to DokuWiki'
        }
        else {
            Write-Error 'Internal conversion function _ConvertTo-WikiMarkupFromMarkdown not available' -ErrorAction Stop
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to DokuWiki: $_" -ErrorAction SilentlyContinue
    }
}
Set-AgentModeAlias -Name 'markdown-to-dokuwiki' -Target 'ConvertTo-DokuwikiFromMarkdown'

function ConvertTo-JiraFromMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InputPath,
        [string]$OutputPath,
        [string]$SourceDialect = 'gfm'
    )

    if (-not $global:FileConversionDocumentsInitialized) { Ensure-FileConversion-Documents }
    try {
        if (Get-Command _ConvertTo-WikiMarkupFromMarkdown -ErrorAction SilentlyContinue) {
            _ConvertTo-WikiMarkupFromMarkdown -InputPath $InputPath -OutputPath $OutputPath `
                -WikiFormat 'jira' -SourceDialect $SourceDialect -OutputExtension '.jira' `
                -ErrorLabel 'Markdown to Jira/Confluence'
        }
        else {
            Write-Error 'Internal conversion function _ConvertTo-WikiMarkupFromMarkdown not available' -ErrorAction Stop
        }
    }
    catch {
        Write-Error "Failed to convert Markdown to Jira/Confluence: $_" -ErrorAction SilentlyContinue
    }
}
Set-AgentModeAlias -Name 'markdown-to-jira' -Target 'ConvertTo-JiraFromMarkdown'
Set-AgentModeAlias -Name 'markdown-to-confluence' -Target 'ConvertTo-JiraFromMarkdown'
