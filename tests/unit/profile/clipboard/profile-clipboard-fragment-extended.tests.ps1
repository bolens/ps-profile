# ===============================================
# profile-clipboard-fragment-extended.tests.ps1
# Execution tests for clipboard.ps1 fragment behavior
# ===============================================

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

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'clipboard.ps1')
}

Describe 'profile.d/clipboard.ps1 extended scenarios' {
    It 'Registers Copy-ToClipboard and cb alias' {
        Get-Command Copy-ToClipboard -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command cb -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias cb).ResolvedCommandName | Should -Be 'Copy-ToClipboard'
    }

    It 'Registers Get-FromClipboard and pb alias' {
        Get-Command Get-FromClipboard -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command pb -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias pb).ResolvedCommandName | Should -Be 'Get-FromClipboard'
    }

    It 'Copy-ToClipboard executes without error when Set-Clipboard is available' {
        Mark-TestCommandsUnavailable -CommandNames @('Set-Clipboard', 'Get-Clipboard')
        Set-TestCommandAvailabilityState -CommandName 'Set-Clipboard' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        { 'clipboard fragment probe' | Copy-ToClipboard } | Should -Not -Throw
    }
}
