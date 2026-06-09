# ===============================================
# profile-bootstrap-tool-install-registry-extended.tests.ps1
# Execution tests for bootstrap/ToolInstallRegistry.ps1 behavior
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

Describe 'profile.d/bootstrap/ToolInstallRegistry.ps1 extended scenarios' {
    It 'Registers tool install registry helpers' {
        Get-Command Get-ToolInstallMethodRegistry -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-InstallMethodFallbackChain -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-ToolSpecificInstallMethod -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Get-ToolInstallMethodRegistry returns install metadata entries' {
        $registry = Get-ToolInstallMethodRegistry
        @($registry).Count | Should -BeGreaterThan 0
    }

    It 'Preserves tool install registry helper bodies on repeated module loads' {
        $firstRegistry = Get-Command Get-ToolInstallMethodRegistry -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'ToolInstallRegistry.ps1')

        (Get-Command Get-ToolInstallMethodRegistry -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstRegistry.ScriptBlock.ToString()
    }
}
