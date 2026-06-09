# ===============================================
# profile-bootstrap-module-loading-extended.tests.ps1
# Execution tests for bootstrap/ModuleLoading.ps1 behavior
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

Describe 'profile.d/bootstrap/ModuleLoading.ps1 extended scenarios' {
    It 'Registers fragment module loading helpers' {
        Get-Command Import-FragmentModule -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Import-FragmentModules -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-FragmentModulePath -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Test-FragmentModulePath validates existing fragment module paths' {
        Test-FragmentModulePath -Path (Join-Path $script:BootstrapDir 'UserHome.ps1') | Should -Be $true
        Test-FragmentModulePath -Path (Join-Path $script:BootstrapDir 'does-not-exist.ps1') | Should -Be $false
    }

    It 'Preserves module loading helper bodies on repeated module loads' {
        $firstImport = Get-Command Import-FragmentModules -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'ModuleLoading.ps1')

        (Get-Command Import-FragmentModules -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstImport.ScriptBlock.ToString()
    }
}
