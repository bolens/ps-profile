<#
tests/unit/utility-generate-docs.tests.ps1

.SYNOPSIS
    Behavioral unit tests for generate-docs.ps1 dry-run execution with an isolated profile path.
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
    $script:GenerateDocsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'docs' 'generate-docs.ps1'
    $ConfirmPreference = 'None'
}

Describe 'generate-docs.ps1 execution' {
    It 'DryRun previews documentation generation for an isolated profile directory' {
        $profileDir = New-TestTempDirectory -Prefix 'GenerateDocsProfile'
        $outputDir = New-TestTempDirectory -Prefix 'GenerateDocsOutput'
        Set-Content -LiteralPath (Join-Path $profileDir '00-fixture.ps1') -Value @'
<#
.SYNOPSIS
    Fixture function for documentation generation.
.DESCRIPTION
    Used by generate-docs behavioral tests.
#>
function Get-GenerateDocsFixture {
    'ok'
}
'@ -Encoding UTF8

        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:GenerateDocsScript -ArgumentList @(
                '-DryRun',
                '-ProfilePath', $profileDir,
                '-OutputPath', $outputDir
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'DRY RUN|Dry run|Would generate'
        }
        finally {
            foreach ($path in @($profileDir, $outputDir)) {
                if (Test-Path -LiteralPath $path) {
                    Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    It 'Writes function markdown to an isolated output directory' {
        $profileDir = New-TestTempDirectory -Prefix 'GenerateDocsApplyProfile'
        $outputDir = New-TestTempDirectory -Prefix 'GenerateDocsApplyOutput'
        Set-Content -LiteralPath (Join-Path $profileDir '00-fixture.ps1') -Value @'
<#
.SYNOPSIS
    Fixture function for documentation generation.
.DESCRIPTION
    Used by generate-docs behavioral tests.
#>
function Get-GenerateDocsFixture {
    'ok'
}
'@ -Encoding UTF8

        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:GenerateDocsScript -ArgumentList @(
                '-ProfilePath', $profileDir,
                '-OutputPath', $outputDir
            )

            $result.ExitCode | Should -Be 0
            $expectedDoc = Join-Path $outputDir 'functions' 'Get-GenerateDocsFixture.md'
            Test-Path -LiteralPath $expectedDoc | Should -BeTrue
            Get-Content -LiteralPath $expectedDoc -Raw | Should -Match 'Get-GenerateDocsFixture'
        }
        finally {
            foreach ($path in @($profileDir, $outputDir)) {
                if (Test-Path -LiteralPath $path) {
                    Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    It 'Runs incremental generation for an isolated profile directory' {
        $profileDir = New-TestTempDirectory -Prefix 'GenerateDocsIncrementalProfile'
        $outputDir = New-TestTempDirectory -Prefix 'GenerateDocsIncrementalOutput'
        Set-Content -LiteralPath (Join-Path $profileDir '00-fixture.ps1') -Value @'
<#
.SYNOPSIS
    Fixture function for incremental documentation generation.
.DESCRIPTION
    Used by generate-docs incremental behavioral tests.
#>
function Get-GenerateDocsIncrementalFixture {
    'ok'
}
'@ -Encoding UTF8

        try {
            $initial = Invoke-TestScriptFile -ScriptPath $script:GenerateDocsScript -ArgumentList @(
                '-ProfilePath', $profileDir,
                '-OutputPath', $outputDir
            )
            $initial.ExitCode | Should -Be 0

            $result = Invoke-TestScriptFile -ScriptPath $script:GenerateDocsScript -ArgumentList @(
                '-Incremental',
                '-ProfilePath', $profileDir,
                '-OutputPath', $outputDir
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Incremental mode|Incremental'
        }
        finally {
            foreach ($path in @($profileDir, $outputDir)) {
                if (Test-Path -LiteralPath $path) {
                    Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
