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
}
