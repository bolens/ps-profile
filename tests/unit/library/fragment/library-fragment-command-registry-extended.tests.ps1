<#
tests/unit/library-fragment-command-registry-extended.tests.ps1
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
    $script:ModulePath = Join-Path $script:TestRepoRoot 'scripts/lib/fragment/FragmentCommandRegistry.psm1'
}
Describe 'scripts/lib/fragment/FragmentCommandRegistry.psm1 extended scenarios' {
    It 'Documents fragment command registry for on-demand access' {
        $c = Get-Content -LiteralPath $script:ModulePath -Raw
        $c | Should -Match 'Fragment command registry for on-demand fragment command access'
        $c | Should -Match 'enum FragmentCommandType'
    }
    It 'Defines Initialize-FragmentCommandRegistry and Register-FragmentCommand' {
        $c = Get-Content -LiteralPath $script:ModulePath -Raw
        $c | Should -Match 'Initialize-FragmentCommandRegistry'
        $c | Should -Match 'Register-FragmentCommand'
        $c | Should -Match 'FragmentCommandRegistry'
    }
    It 'Supports registry lookup export and bulk registration helpers' {
        $c = Get-Content -LiteralPath $script:ModulePath -Raw
        $c | Should -Match 'Get-FragmentForCommand'
        $c | Should -Match 'Export-CommandRegistry'
        $c | Should -Match 'Register-AllFragmentCommands'
        $c | Should -Match 'Register-CommandsFromFragment'
        $c | Should -Match 'Create-CommandProxiesForAutocomplete'
    }
}
