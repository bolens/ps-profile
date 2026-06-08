# ===============================================
# profile-eza-fragment-extended.tests.ps1
# Execution tests for eza.ps1 fragment behavior
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
    Mark-TestCommandsUnavailable -CommandNames @('eza')
    Set-TestCommandAvailabilityState -CommandName 'eza' -Available $true
    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }
    . (Join-Path $script:ProfileDir 'eza.ps1')
}

Describe 'profile.d/eza.ps1 extended scenarios' {
    It 'Registers eza-backed listing functions when eza is available' {
        Get-Command Get-ChildItemEza -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-ChildItemEzaLong -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-ChildItemEzaTree -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-ChildItemEzaGit -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Registers ll and la aliases targeting eza listing helpers' {
        Get-Alias ll -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias ll).ResolvedCommandName | Should -Be 'Get-ChildItemEzaLong'
        Get-Alias la -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias la).ResolvedCommandName | Should -Be 'Get-ChildItemEzaAll'
    }

    It 'Registers tree and git-aware listing aliases lt and lg' {
        Get-Alias lt -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias lt).ResolvedCommandName | Should -Be 'Get-ChildItemEzaTree'
        Get-Alias lg -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias lg).ResolvedCommandName | Should -Be 'Get-ChildItemEzaGit'
    }
}
