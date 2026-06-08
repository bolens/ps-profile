<#
tests/unit/utility-generate-fragment-readmes.tests.ps1

.SYNOPSIS
    Behavioral unit tests for generate-fragment-readmes.ps1 dry-run execution.
#>

function global:Invoke-GenerateFragmentReadmesScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:FragmentReadmesScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

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
    $script:FragmentReadmesScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'docs' 'generate-fragment-readmes.ps1'
    $script:ProfileDir = Join-Path $script:TestRepoRoot 'profile.d'
    $ConfirmPreference = 'None'
}

Describe 'generate-fragment-readmes.ps1 execution' {
    It 'DryRun previews README generation without writing files' {
        if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
            Set-ItResult -Skipped -Because 'profile.d directory not found'
            return
        }

        $result = Invoke-GenerateFragmentReadmesScript -ArgumentList @('-DryRun')

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'DRY RUN'
        $result.Output | Should -Match 'Would generate'
    }

    It 'DryRun previews README generation for a custom output directory' {
        if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
            Set-ItResult -Skipped -Because 'profile.d directory not found'
            return
        }

        $outputRel = 'tests/test-data/fragment-readmes-preview'
        $result = Invoke-GenerateFragmentReadmesScript -ArgumentList @(
            '-DryRun',
            '-OutputPath', $outputRel
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'DRY RUN|Would generate'
        $result.Output | Should -Match 'Would copy fragment READMEs to output directory|Would generate fragment index'
    }

    It 'Writes fragment README files for an isolated profile directory' {
        $repo = New-TestTempDirectory -Prefix 'GenerateFragmentReadmesApply'
        try {
            $docsDir = Join-Path $repo 'scripts' 'utils' 'docs'
            $profileDir = Join-Path $repo 'profile.d'
            $outputDir = Join-Path $repo 'docs' 'fragments'
            $null = New-Item -ItemType Directory -Path $docsDir -Force
            $null = New-Item -ItemType Directory -Path $profileDir -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'lib') -Destination (Join-Path $repo 'scripts' 'lib') -Recurse -Force
            Copy-Item -LiteralPath (Join-Path $script:TestRepoRoot 'scripts' 'utils' 'docs' 'modules') -Destination (Join-Path $docsDir 'modules') -Recurse -Force
            Copy-Item -LiteralPath $script:FragmentReadmesScript -Destination (Join-Path $docsDir 'generate-fragment-readmes.ps1') -Force

            Set-Content -LiteralPath (Join-Path $profileDir 'fixture.ps1') -Value @'
# Fixture fragment for README generation tests.
function Get-FragmentReadmeFixture {
    'ok'
}
'@ -Encoding UTF8

            Push-Location $repo
            try {
                git init -q | Out-Null
                git config user.email 'fixture@example.com'
                git config user.name 'Fixture'
                git add profile.d/fixture.ps1
                git commit -m 'init fragment readme fixture' -q
            }
            finally {
                Pop-Location
            }

            $scriptPath = Join-Path $docsDir 'generate-fragment-readmes.ps1'
            Push-Location $repo
            try {
                $result = Invoke-TestScriptFile -ScriptPath $scriptPath -ArgumentList @(
                    '-Force',
                    '-OutputPath', $outputDir
                )
            }
            finally {
                Pop-Location
            }

            $result.ExitCode | Should -Be 0
            $expectedReadme = Join-Path $outputDir 'fixture.md'
            Test-Path -LiteralPath $expectedReadme | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $outputDir 'README.md') | Should -BeTrue
            Get-Content -LiteralPath $expectedReadme -Raw | Should -Match 'Get-FragmentReadmeFixture|fixture'
            Test-Path -LiteralPath (Join-Path $profileDir 'fixture.ps1.README.md') | Should -BeFalse
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
