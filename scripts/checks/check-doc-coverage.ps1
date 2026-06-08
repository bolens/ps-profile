<#
scripts/checks/check-doc-coverage.ps1

.SYNOPSIS
    Reports documentation coverage gaps for profile commands and generated API docs.

.DESCRIPTION
    Compares parsed profile documentation with dynamic registrations and markdown
    output under docs/api. By default this is informational. Use -Strict to fail on
    parser gaps or missing markdown files.

.PARAMETER ProfilePath
    Profile fragment root. Defaults to profile.d under the repository root.

.PARAMETER DocsPath
    Generated API documentation root. Defaults to docs/api.

.PARAMETER Strict
    Treat parser gaps and missing markdown as validation failures.

.PARAMETER Json
    Emit the full coverage report as JSON.

.EXAMPLE
    pwsh -NoProfile -File scripts/checks/check-doc-coverage.ps1

    Prints a coverage summary for profile.d and docs/api.

.EXAMPLE
    pwsh -NoProfile -File scripts/checks/check-doc-coverage.ps1 -Strict

    Fails when resolvable help or markdown files are missing from the pipeline.
#>

param(
    [string]$ProfilePath,
    [string]$DocsPath = 'docs/api',
    [switch]$Strict,
    [switch]$Json
)

$scriptsDir = Split-Path -Parent $PSScriptRoot
$pathResolutionPath = Join-Path $scriptsDir 'lib' 'path' 'PathResolution.psm1'
Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop

$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    if (-not $ProfilePath) {
        $ProfilePath = Join-Path $repoRoot 'profile.d'
    }
    elseif (-not [System.IO.Path]::IsPathRooted($ProfilePath)) {
        $ProfilePath = Join-Path $repoRoot $ProfilePath
    }

    if (-not [System.IO.Path]::IsPathRooted($DocsPath)) {
        $DocsPath = Join-Path $repoRoot $DocsPath
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$docCoveragePath = Join-Path $repoRoot 'scripts' 'utils' 'docs' 'modules' 'DocCoverage.psm1'
if (-not (Test-Path -LiteralPath $docCoveragePath)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "DocCoverage module not found at: $docCoveragePath"
}

Remove-Module DocCoverage -ErrorAction SilentlyContinue
Import-Module $docCoveragePath -DisableNameChecking -Force -ErrorAction Stop

try {
    $report = Get-DocumentationCoverageReport -ProfilePath $ProfilePath -DocsPath $DocsPath
}
catch {
    Exit-WithCode -ExitCode $EXIT_RUNTIME_ERROR -ErrorRecord $_
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message 'Documentation coverage report emitted as JSON.'
}

Write-ScriptMessage -Message 'Documentation coverage summary:'
Write-ScriptMessage -Message "  Documented functions: $($report.DocumentedFunctionCount)"
Write-ScriptMessage -Message "  Documented aliases: $($report.DocumentedAliasCount)"
Write-ScriptMessage -Message "  Dynamic registrations scanned: $($report.DynamicRegistrationCount)"
Write-ScriptMessage -Message "  Dynamic registrations without resolvable help: $($report.RegistrationsWithoutHelp.Count)"
Write-ScriptMessage -Message "  Parser gaps (help found, not documented): $($report.ParserGaps.Count)"
Write-ScriptMessage -Message "  Weak help entries: $($report.WeakHelp.Count)"
Write-ScriptMessage -Message "  Missing markdown files: $($report.MissingMarkdown.Count)"
Write-ScriptMessage -Message "  Orphan markdown files: $($report.OrphanMarkdown.Count)"

if ($report.ParserGaps.Count -gt 0) {
    Write-ScriptMessage -Message 'Parser gaps:'
    foreach ($gap in $report.ParserGaps | Select-Object -First 20) {
        Write-ScriptMessage -Message "  $($gap.Name) ($($gap.File))"
    }
    if ($report.ParserGaps.Count -gt 20) {
        Write-ScriptMessage -Message "  ... and $($report.ParserGaps.Count - 20) more"
    }
}

if ($report.RegistrationsWithoutHelp.Count -gt 0) {
    Write-ScriptMessage -Message 'Dynamic registrations without resolvable help (informational):'
    foreach ($entry in $report.RegistrationsWithoutHelp | Select-Object -First 20) {
        Write-ScriptMessage -Message "  $($entry.Name) ($($entry.File))"
    }
    if ($report.RegistrationsWithoutHelp.Count -gt 20) {
        Write-ScriptMessage -Message "  ... and $($report.RegistrationsWithoutHelp.Count - 20) more"
    }
}

if ($report.MissingMarkdown.Count -gt 0) {
    Write-ScriptMessage -Message 'Missing markdown files:'
    foreach ($entry in $report.MissingMarkdown | Select-Object -First 20) {
        Write-ScriptMessage -Message "  $($entry.Type) $($entry.Name)"
    }
    if ($report.MissingMarkdown.Count -gt 20) {
        Write-ScriptMessage -Message "  ... and $($report.MissingMarkdown.Count - 20) more"
    }
}

$failureCount = 0
if ($Strict) {
    $failureCount = $report.ParserGaps.Count + $report.MissingMarkdown.Count
}

if ($failureCount -gt 0) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Documentation coverage check failed with $failureCount blocking issue(s)."
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message 'Documentation coverage check completed.'
