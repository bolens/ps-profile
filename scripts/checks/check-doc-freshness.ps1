<#
scripts/checks/check-doc-freshness.ps1

.SYNOPSIS
    Verifies committed API documentation matches incremental generator output.

.DESCRIPTION
    Generates API documentation from scratch in a temporary directory and compares
    the result with the committed tree. The tracked documentation is never modified,
    and stale incremental cache state cannot affect validation.

.PARAMETER ProfilePath
    Optional profile root passed through to generate-docs.ps1.

.PARAMETER DocsPath
    Output directory for generated docs. Defaults to docs/api.

.PARAMETER GeneratorPath
    Optional path to the documentation generator. Intended for isolated validation
    and testing; defaults to the repository generator.

.EXAMPLE
    pwsh -NoProfile -File scripts/checks/check-doc-freshness.ps1

    Regenerates docs in a temporary directory and fails if the output differs from
    docs/api.
#>

param(
    [string]$ProfilePath,
    [string]$DocsPath = 'docs/api',
    [string]$GeneratorPath
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

$generateDocs = if ($GeneratorPath) {
    if ([System.IO.Path]::IsPathRooted($GeneratorPath)) {
        $GeneratorPath
    }
    else {
        Join-Path $repoRoot $GeneratorPath
    }
}
else {
    Join-Path $repoRoot 'scripts' 'utils' 'docs' 'generate-docs.ps1'
}
if (-not (Test-Path -LiteralPath $generateDocs)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "generate-docs.ps1 not found at: $generateDocs"
}

$psExe = Get-PowerShellExecutable
$trackedDocsPath = if ([System.IO.Path]::IsPathRooted($DocsPath)) {
    $DocsPath
}
else {
    $docsRelative = $DocsPath.TrimStart('.', '\', '/')
    if ([string]::IsNullOrWhiteSpace($docsRelative)) {
        $docsRelative = 'docs/api'
    }
    Join-Path $repoRoot $docsRelative
}
if (-not (Test-Path -LiteralPath $trackedDocsPath -PathType Container)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Documentation directory not found at: $trackedDocsPath"
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "ps-profile-doc-freshness-$([guid]::NewGuid().ToString('N'))"
$tempDocsPath = Join-Path $tempRoot 'api'

try {
    $null = New-Item -ItemType Directory -Path $tempRoot -Force
    $null = New-Item -ItemType Directory -Path $tempDocsPath -Force

    $generateArgs = @(
        '-NoProfile'
        '-File'
        $generateDocs
        '-OutputPath'
        $tempDocsPath
    )

    if ($ProfilePath) {
        $generateArgs += @('-ProfilePath', $ProfilePath)
    }

    Write-ScriptMessage -Message "Regenerating API docs in a temporary directory via: $generateDocs"
    $generationOutput = @(& $psExe @generateArgs 2>&1)
    if ($LASTEXITCODE -ne 0) {
        foreach ($line in ($generationOutput | Select-Object -Last 50)) {
            Write-ScriptMessage -Message "  $line"
        }
        Exit-WithCode -ExitCode $EXIT_RUNTIME_ERROR -Message "generate-docs.ps1 failed with exit code $LASTEXITCODE"
    }

    $getDocumentationSnapshot = {
        param([string]$Root)

        $snapshot = @{}
        Get-ChildItem -LiteralPath $Root -Recurse -File |
            Where-Object { $_.Name -ne '.doc-generation-cache.json' } |
            ForEach-Object {
                $relativePath = [System.IO.Path]::GetRelativePath($Root, $_.FullName) -replace '\\', '/'
                $content = [System.IO.File]::ReadAllText($_.FullName)
                # Generated source links are relative to the output directory. A
                # temporary output root therefore changes only the prefix, not the
                # referenced profile source. Canonicalize that prefix for comparison.
                $content = $content -replace '(?m)^Defined in: .*?(profile\.d/.*)$', 'Defined in: $1'
                # The index generation timestamp is informational, not API content.
                $content = $content -replace '(?m)^\*\*Generated:\*\* .+$', '**Generated:** <normalized>'
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
                $hash = [System.Security.Cryptography.SHA256]::HashData($bytes)
                $snapshot[$relativePath] = [Convert]::ToHexString($hash)
            }
        return $snapshot
    }

    $trackedSnapshot = & $getDocumentationSnapshot $trackedDocsPath
    $generatedSnapshot = & $getDocumentationSnapshot $tempDocsPath
    $changedFiles = [System.Collections.Generic.List[string]]::new()
    foreach ($relativePath in @($trackedSnapshot.Keys + $generatedSnapshot.Keys | Sort-Object -Unique)) {
        if (-not $trackedSnapshot.ContainsKey($relativePath)) {
            $changedFiles.Add("added: $relativePath")
        }
        elseif (-not $generatedSnapshot.ContainsKey($relativePath)) {
            $changedFiles.Add("removed: $relativePath")
        }
        elseif ($trackedSnapshot[$relativePath] -ne $generatedSnapshot[$relativePath]) {
            $changedFiles.Add("changed: $relativePath")
        }
    }

    if ($changedFiles.Count -gt 0) {
        Write-ScriptMessage -Message 'Generated API documentation is out of date:'
        foreach ($line in ($changedFiles | Select-Object -First 50)) {
            Write-ScriptMessage -Message "  $line"
        }
        Write-ScriptMessage -Message "Run 'task generate-docs' or 'task generate-docs-incremental' and commit docs/api changes."
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message 'API documentation freshness check failed.'
    }
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$successMessage = 'API documentation is up to date.'
if ($GeneratorPath -and $env:PS_PROFILE_TEST_MODE -eq '1') {
    Write-ScriptMessage -Message $successMessage
    return
}
Exit-WithCode -ExitCode $EXIT_SUCCESS -Message $successMessage
