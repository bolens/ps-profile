<#
tests/unit/profile-bottom-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bottom.ps1'
}
Describe 'profile.d/bottom.ps1 extended scenarios' {
    It 'Declares standard tier and resolves btm or bottom command name' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match "Test-CachedCommand btm"
        $c | Should -Match "Test-CachedCommand bottom"
    }
    It 'Aliases top htop and monitor to bottom system monitor' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-Alias -Name top -Value"
        $c | Should -Match "Set-Alias -Name htop -Value"
        $c | Should -Match "Set-Alias -Name monitor -Value"
    }
    It 'Calls Invoke-MissingToolWarning when neither btm nor bottom is found' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-MissingToolWarning'
        $c | Should -Match "ToolName 'bottom'"
    }
}
