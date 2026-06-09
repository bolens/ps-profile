# ===============================================
# profile-bootstrap-module-path-cache-extended.tests.ps1
# Execution tests for bootstrap/ModulePathCache.ps1 behavior
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

Describe 'profile.d/bootstrap/ModulePathCache.ps1 extended scenarios' {
    It 'Registers module path cache helpers' {
        Get-Command Test-ModulePath -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Clear-ModulePathCache -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Remove-ModulePathCacheEntry -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Test-ModulePath returns true for an existing bootstrap module file' {
        $bootstrapPath = Join-Path $script:BootstrapDir 'CommandCache.ps1'
        Test-ModulePath -Path $bootstrapPath | Should -Be $true
        Test-ModulePath -Path (Join-Path $script:BootstrapDir 'missing-module.ps1') | Should -Be $false
    }

    It 'Preserves module path cache helper bodies on repeated module loads' {
        $firstTest = Get-Command Test-ModulePath -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'ModulePathCache.ps1')

        (Get-Command Test-ModulePath -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstTest.ScriptBlock.ToString()
    }
}
