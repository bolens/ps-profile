<#
tests/unit/utility-build-fragment-cache.tests.ps1

.SYNOPSIS
    Behavioral unit tests for build-fragment-cache.ps1 dry-run execution.
#>

function global:Invoke-BuildFragmentCacheScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:BuildCacheScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:BuildCacheScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'build-fragment-cache.ps1'
    $script:ProfileDir = Join-Path $script:TestRepoRoot 'profile.d'
    $ConfirmPreference = 'None'
}

Describe 'build-fragment-cache.ps1 execution' {
    It 'WhatIf previews cache building for the repository profile.d' {
        if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
            Set-ItResult -Skipped -Because 'profile.d directory not found'
            return
        }

        $result = Invoke-BuildFragmentCacheScript -ArgumentList @(
            '-WhatIf',
            '-FragmentPath', $script:ProfileDir
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match '\[WhatIf\]'
        $result.Output | Should -Match 'Would build cache for [1-9]\d* fragment'
    }
}
