<#
scripts/checks/check-doc-freshness.ps1

.SYNOPSIS
    Verifies committed API documentation matches incremental generator output.

.DESCRIPTION
    Runs generate-docs.ps1 with -Incremental, then fails when docs/api has unstaged
    changes. Intended for CI to ensure pull requests refresh generated markdown.

.PARAMETER ProfilePath
    Optional profile root passed through to generate-docs.ps1.

.PARAMETER DocsPath
    Output directory for generated docs. Defaults to docs/api.

.EXAMPLE
    pwsh -NoProfile -File scripts/checks/check-doc-freshness.ps1

    Regenerates docs incrementally and fails if git detects changes under docs/api.
#>

param(
    [string]$ProfilePath,
    [string]$DocsPath = 'docs/api'
)

$scriptsDir = Split-Path -Parent $PSScriptRoot
$pathResolutionPath = Join-Path $scriptsDir 'lib' 'path' 'PathResolution.psm1'
Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop

$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PowerShellDetection' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$generateDocs = Join-Path $repoRoot 'scripts' 'utils' 'docs' 'generate-docs.ps1'
if (-not (Test-Path -LiteralPath $generateDocs)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "generate-docs.ps1 not found at: $generateDocs"
}

$psExe = Get-PowerShellExecutable
$generateArgs = @(
    '-NoProfile'
    '-File'
    $generateDocs
    '-Incremental'
    '-OutputPath'
    $DocsPath
)

if ($ProfilePath) {
    $generateArgs += @('-ProfilePath', $ProfilePath)
}

Write-ScriptMessage -Message "Regenerating API docs incrementally via: $generateDocs"
& $psExe @generateArgs
if ($LASTEXITCODE -ne 0) {
    Exit-WithCode -ExitCode $EXIT_RUNTIME_ERROR -Message "generate-docs.ps1 failed with exit code $LASTEXITCODE"
}

$docsRelative = $DocsPath.TrimStart('.', '\', '/')
if ([string]::IsNullOrWhiteSpace($docsRelative)) {
    $docsRelative = 'docs/api'
}

Push-Location $repoRoot
try {
    $changedFiles = @(git status --porcelain -- $docsRelative 2>$null)
    if ($changedFiles.Count -gt 0) {
        Write-ScriptMessage -Message 'Generated API documentation is out of date:'
        foreach ($line in $changedFiles) {
            Write-ScriptMessage -Message "  $line"
        }
        Write-ScriptMessage -Message "Run 'task generate-docs' or 'task generate-docs-incremental' and commit docs/api changes."
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message 'API documentation freshness check failed.'
    }
}
finally {
    Pop-Location
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message 'API documentation is up to date.'
