# ===============================================
# profile-dev-fragment-extended.tests.ps1
# Execution tests for dev.ps1 fragment behavior
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
}

Describe 'profile.d/dev.ps1 extended scenarios' {
    It 'Registers idempotent docker and language shortcut wrappers' {
        . (Join-Path $script:ProfileDir 'dev.ps1')

        Get-Command d -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command dc -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command n -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command py -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Registers podman, npm, and cargo shortcut wrappers' {
        . (Join-Path $script:ProfileDir 'dev.ps1')

        Get-Command pd -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ni -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command cr -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Preserves existing shortcut bodies on repeated fragment loads' {
        . (Join-Path $script:ProfileDir 'dev.ps1')
        $firstDocker = Get-Command d -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'dev.ps1')

        (Get-Command d -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstDocker.ScriptBlock.ToString()
    }
}
