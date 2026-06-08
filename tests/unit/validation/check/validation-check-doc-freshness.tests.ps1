<#
tests/unit/validation-check-doc-freshness.tests.ps1

.SYNOPSIS
    Behavioral smoke test for check-doc-freshness.ps1.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CheckDocFreshnessScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-doc-freshness.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-doc-freshness.ps1 execution' {
    It 'Regenerates docs incrementally and reports freshness status' {
        if ($env:CI -or $env:GITHUB_ACTIONS) {
            Set-ItResult -Skipped -Because 'incremental doc generation is too slow for CI'
            return
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:CheckDocFreshnessScript

        $result.Output | Should -Match 'Regenerating API docs incrementally|generate-docs'
        $result.Output | Should -Match 'API documentation is up to date|freshness check failed|out of date'
        $result.ExitCode | Should -BeIn @(0, 1)
    }

    It 'Passes in an isolated repository when incremental generation leaves docs unchanged' {
        $repo = New-TestTempDirectory -Prefix 'DocFreshnessClean'
        try {
            $checksDir = Join-Path $repo 'scripts' 'checks'
            $docsDir = Join-Path $repo 'docs' 'api'
            $generateDir = Join-Path $repo 'scripts' 'utils' 'docs'
            $null = New-Item -ItemType Directory -Path $checksDir -Force
            $null = New-Item -ItemType Directory -Path $docsDir -Force
            $null = New-Item -ItemType Directory -Path $generateDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:CheckDocFreshnessScript -Destination (Join-Path $checksDir 'check-doc-freshness.ps1') -Force

            $noopGenerate = @'
param([switch]$Incremental, [string]$OutputPath, [string]$ProfilePath)
exit 0
'@
            Set-Content -LiteralPath (Join-Path $generateDir 'generate-docs.ps1') -Value $noopGenerate -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $docsDir 'README.md') -Value '# api docs fixture' -Encoding UTF8

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'
                git add docs/api/README.md
                git commit -m 'init docs' -q
            }
            finally {
                Pop-Location
            }

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $checksDir 'check-doc-freshness.ps1')

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'API documentation is up to date'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails in an isolated repository when incremental generation modifies docs/api' {
        $repo = New-TestTempDirectory -Prefix 'DocFreshnessStale'
        try {
            $checksDir = Join-Path $repo 'scripts' 'checks'
            $docsDir = Join-Path $repo 'docs' 'api'
            $generateDir = Join-Path $repo 'scripts' 'utils' 'docs'
            $null = New-Item -ItemType Directory -Path $checksDir -Force
            $null = New-Item -ItemType Directory -Path $docsDir -Force
            $null = New-Item -ItemType Directory -Path $generateDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath $script:CheckDocFreshnessScript -Destination (Join-Path $checksDir 'check-doc-freshness.ps1') -Force

            $staleGenerate = @'
param([switch]$Incremental, [string]$OutputPath, [string]$ProfilePath)
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$relative = if ($OutputPath) { $OutputPath } else { 'docs/api' }
$outDir = Join-Path $repoRoot $relative
$target = Join-Path $outDir 'stale-output.md'
Set-Content -LiteralPath $target -Value 'generated stale doc' -Encoding UTF8
exit 0
'@
            Set-Content -LiteralPath (Join-Path $generateDir 'generate-docs.ps1') -Value $staleGenerate -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $docsDir 'README.md') -Value '# api docs fixture' -Encoding UTF8

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'
                git add docs/api/README.md
                git commit -m 'init docs' -q
            }
            finally {
                Pop-Location
            }

            $result = Invoke-TestScriptFile -ScriptPath (Join-Path $checksDir 'check-doc-freshness.ps1')

            $result.ExitCode | Should -Be 1
            $result.Output | Should -Match 'out of date|freshness check failed'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
