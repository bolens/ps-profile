<#
tests/unit/validation/check/validation-check-doc-freshness.tests.ps1

.SYNOPSIS
    Behavioral tests for check-doc-freshness.ps1.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $null -eq $current.Parent) { break }
        $current = $current.Parent
    }

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CheckDocFreshnessScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-doc-freshness.ps1'
}

Describe 'check-doc-freshness.ps1 execution' {
    BeforeEach {
        $script:FixtureRoot = New-TestTempDirectory -Prefix 'DocFreshness'
        $script:TrackedDocs = Join-Path $script:FixtureRoot 'tracked'
        $script:Generator = Join-Path $script:FixtureRoot 'generate-docs.ps1'
        $null = New-Item -ItemType Directory -Path $script:TrackedDocs -Force

        $generatorContent = @'
param([string]$OutputPath, [string]$ProfilePath)
$null = New-Item -ItemType Directory -Path $OutputPath -Force

switch ($ProfilePath) {
    'fail' {
        Write-Output 'fixture generation failed'
        exit 7
    }
    'stale' {
        Set-Content -LiteralPath (Join-Path $OutputPath 'README.md') -Value 'generated content' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $OutputPath 'added.md') -Value 'added content' -Encoding UTF8
    }
    default {
        @(
            '# API'
            '**Generated:** 2099-12-31'
            'Defined in: ../../temporary/output/profile.d/example.ps1'
        ) | Set-Content -LiteralPath (Join-Path $OutputPath 'README.md') -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $OutputPath '.doc-generation-cache.json') -Value '{}' -Encoding UTF8
    }
}
'@
        Set-Content -LiteralPath $script:Generator -Value $generatorContent -Encoding UTF8
    }

    It 'accepts absolute documentation and generator paths portably' {
        @(
            '# API'
            '**Generated:** 2000-01-01'
            'Defined in: ../../../repo/profile.d/example.ps1'
        ) | Set-Content -LiteralPath (Join-Path $script:TrackedDocs 'README.md') -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:TrackedDocs '.doc-generation-cache.json') -Value '{"stale":true}' -Encoding UTF8

        $output = & $script:CheckDocFreshnessScript `
            -DocsPath $script:TrackedDocs `
            -GeneratorPath $script:Generator 2>&1 | Out-String

        $output | Should -Match 'Regenerating API docs'
        $output | Should -Match 'API documentation is up to date'
    }

    It 'reports added, removed, and changed generated documentation' {
        Set-Content -LiteralPath (Join-Path $script:TrackedDocs 'README.md') -Value 'tracked content' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $script:TrackedDocs 'removed.md') -Value 'removed content' -Encoding UTF8

        {
            & $script:CheckDocFreshnessScript `
                -ProfilePath 'stale' `
                -DocsPath $script:TrackedDocs `
                -GeneratorPath $script:Generator
        } | Should -Throw '*freshness check failed*'
    }

    It 'reports generator failures and their captured output' {
        Set-Content -LiteralPath (Join-Path $script:TrackedDocs 'README.md') -Value 'tracked content' -Encoding UTF8

        {
            & $script:CheckDocFreshnessScript `
                -ProfilePath 'fail' `
                -DocsPath $script:TrackedDocs `
                -GeneratorPath $script:Generator
        } | Should -Throw '*failed with exit code 7*'
    }

    It 'rejects a missing documentation directory' {
        $missingDocs = Join-Path $script:FixtureRoot 'missing'

        {
            & $script:CheckDocFreshnessScript `
                -DocsPath $missingDocs `
                -GeneratorPath $script:Generator
        } | Should -Throw '*Documentation directory not found*'
    }

    It 'rejects a missing generator' {
        $missingGenerator = Join-Path $script:FixtureRoot 'missing-generator.ps1'

        {
            & $script:CheckDocFreshnessScript `
                -DocsPath $script:TrackedDocs `
                -GeneratorPath $missingGenerator
        } | Should -Throw '*generate-docs.ps1 not found*'
    }
}
