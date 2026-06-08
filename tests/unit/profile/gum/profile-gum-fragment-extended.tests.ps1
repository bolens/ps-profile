<#
tests/unit/profile-gum-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/gum.ps1'
}
Describe 'profile.d/gum.ps1 extended scenarios' {
    It 'Declares standard tier for Charmbracelet gum terminal UI helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'github.com/charmbracelet/gum'
    }
    It 'Defines Invoke-GumConfirm Invoke-GumChoose and Invoke-GumInput prompts' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-GumConfirm'
        $c | Should -Match 'Invoke-GumChoose'
    }
    It 'Registers confirm and choose shorthand aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-Alias -Name confirm -Value Invoke-GumConfirm"
        $c | Should -Match "Set-Alias -Name choose -Value Invoke-GumChoose"
    }
}
