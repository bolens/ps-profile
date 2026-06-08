<#
tests/unit/profile-terminal-enhanced-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/terminal-enhanced.ps1'
}
Describe 'profile.d/terminal-enhanced.ps1 extended scenarios' {
    It 'Declares optional tier and uses Test-FragmentLoaded guard' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match "FragmentName 'terminal-enhanced'"
    }
    It 'Defines Launch-Alacritty and Launch-Kitty terminal emulator helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Launch-Alacritty'
        $c | Should -Match 'Launch-Kitty'
    }
    It 'Provides Get-TerminalInfo and marks fragment loaded on success' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TerminalInfo'
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'terminal-enhanced'"
    }
}
