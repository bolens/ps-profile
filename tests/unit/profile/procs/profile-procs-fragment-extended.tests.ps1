<#
tests/unit/profile-procs-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/procs.ps1'
}
Describe 'profile.d/procs.ps1 extended scenarios' {
    It 'Declares standard tier guarded by procs availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand procs\)'
    }
    It 'Aliases ps and psgrep to procs process viewer' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-Alias -Name ps -Value procs"
        $c | Should -Match "Set-Alias -Name psgrep -Value procs"
    }
    It 'Calls Invoke-MissingToolWarning when procs is unavailable' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-MissingToolWarning'
        $c | Should -Match "ToolName 'procs'"
    }
}
