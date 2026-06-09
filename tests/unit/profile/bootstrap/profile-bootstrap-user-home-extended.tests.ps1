# ===============================================
# profile-bootstrap-user-home-extended.tests.ps1
# Execution tests for bootstrap/UserHome.ps1 behavior
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
    $script:BootstrapDir = Join-Path $script:ProfileDir 'bootstrap'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'profile.d/bootstrap/UserHome.ps1 extended scenarios' {
    It 'Registers Get-UserHome helper' {
        Get-Command Get-UserHome -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Get-UserHome returns a non-empty existing directory path' {
        $homePath = Get-UserHome
        $homePath | Should -Not -BeNullOrEmpty
        Test-Path -LiteralPath $homePath -PathType Container | Should -Be $true
    }

    It 'Preserves Get-UserHome body on repeated module loads' {
        $firstHome = Get-Command Get-UserHome -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'UserHome.ps1')

        (Get-Command Get-UserHome -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstHome.ScriptBlock.ToString()
    }
}
