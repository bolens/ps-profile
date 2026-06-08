<#
tests/unit/profile-editors-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/editors.ps1'
}
Describe 'profile.d/editors.ps1 extended scenarios' {
    It 'Declares optional tier for editor and IDE integrations' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Defines Edit-WithVSCode with vscode-insiders fallback chain' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Edit-WithVSCode'
        $c | Should -Match 'vscode-insiders'
    }
    It 'Registers editor helpers with Set-AgentModeFunction and marks fragment loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-AgentModeFunction'
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'editors'"
    }
}
