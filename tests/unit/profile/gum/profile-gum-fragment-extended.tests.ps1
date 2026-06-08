# ===============================================
# profile-gum-fragment-extended.tests.ps1
# Execution tests for gum.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'gum.ps1')
}

Describe 'profile.d/gum.ps1 extended scenarios' {
    It 'Registers gum confirm and choose helper functions' {
        Get-Command Invoke-GumConfirm -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-GumChoose -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command confirm -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command choose -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Registers gum input, spin, and style helper functions' {
        Get-Command Invoke-GumInput -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-GumSpin -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-GumStyle -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command input -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command spin -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command style -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Preserves gum helper bodies on repeated fragment loads' {
        $firstConfirm = Get-Command Invoke-GumConfirm -ErrorAction Stop
        . (Join-Path $script:ProfileDir 'gum.ps1')
        (Get-Command Invoke-GumConfirm -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstConfirm.ScriptBlock.ToString()
    }
}
