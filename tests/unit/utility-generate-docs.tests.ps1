<#
tests/unit/utility-generate-docs.tests.ps1

.SYNOPSIS
    Behavioral unit tests for generate-docs.ps1 dry-run execution with an isolated profile path.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

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
}
