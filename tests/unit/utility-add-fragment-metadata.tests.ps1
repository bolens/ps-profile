<#
tests/unit/utility-add-fragment-metadata.tests.ps1

.SYNOPSIS
    Behavioral unit tests for add-fragment-metadata.ps1 DryRun on a single fragment.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:AddMetadataScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'fragment' 'add-fragment-metadata.ps1'
    $ConfirmPreference = 'None'
}

Describe 'add-fragment-metadata.ps1 execution' {
    It 'DryRun processes a single fragment without modifying files' {
        $fragmentPath = Join-Path $script:TestRepoRoot 'profile.d' 'env.ps1'
        if (-not (Test-Path -LiteralPath $fragmentPath)) {
            Set-ItResult -Skipped -Because 'env.ps1 fragment is not present in this checkout'
            return
        }

        $before = Get-Content -LiteralPath $fragmentPath -Raw
        $result = Invoke-TestScriptFile -ScriptPath $script:AddMetadataScript -ArgumentList @(
            '-Fragment', 'env',
            '-DryRun'
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'DRY RUN|Would update|skipped|Updated'
        (Get-Content -LiteralPath $fragmentPath -Raw) | Should -Be $before
    }

    It 'Fails validation when the requested fragment does not exist' {
        $result = Invoke-TestScriptFile -ScriptPath $script:AddMetadataScript -ArgumentList @(
            '-Fragment', 'definitely-missing-fragment-name',
            '-DryRun'
        )

        $result.ExitCode | Should -BeIn @(1, 2)
        $result.Output | Should -Match 'Fragment not found|definitely-missing-fragment-name'
    }
}
