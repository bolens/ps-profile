<#
tests/unit/utility-clear-fragment-cache.tests.ps1

.SYNOPSIS
    Behavioral unit tests for clear-fragment-cache.ps1 dry-run execution.
#>

function global:Invoke-ClearFragmentCacheScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:ClearCacheScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ClearCacheScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'clear-fragment-cache.ps1'
    $ConfirmPreference = 'None'
}

Describe 'clear-fragment-cache.ps1 execution' {
    It 'WhatIf previews cache clearing without failing' {
        $result = Invoke-ClearFragmentCacheScript -ArgumentList @('-WhatIf')
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match '\[WhatIf\]'
        $result.Output | Should -Match 'Would attempt to clear'
    }
}
