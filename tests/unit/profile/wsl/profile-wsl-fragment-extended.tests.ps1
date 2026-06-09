# ===============================================
# profile-wsl-fragment-extended.tests.ps1
# Execution tests for wsl.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'wsl.ps1')
}

Describe 'profile.d/wsl.ps1 extended scenarios' {
    It 'Registers WSL helper functions and aliases' {
        Get-Command Stop-WSL -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-WSLDistribution -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command wsl-shutdown -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command wsl-list -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ubuntu -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Stop-WSL invokes wsl --shutdown when wsl is available' {
        Clear-TestCommandInvocationCapture
        Setup-CapturingCommandMock -CommandName 'wsl' -Output ''

        Stop-WSL 4>&1 | Out-Null

        Assert-TestCommandInvokedExactlyOnce
        Assert-TestCommandInvocationContains '--shutdown'
    }

    It 'Preserves existing WSL helper bodies on repeated fragment loads' {
        $firstStop = Get-Command Stop-WSL -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'wsl.ps1')

        (Get-Command Stop-WSL -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstStop.ScriptBlock.ToString()
    }
}
