# ===============================================
# profile-utilities-network-advanced-extended.tests.ps1
# Execution tests for utilities-modules/network/utilities-network-advanced.ps1 behavior
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
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
}

function script:Import-NetworkAdvancedModule {
    Microsoft.PowerShell.Utility\Remove-Variable -Name 'NetworkUtilsLoaded' -Scope Global -ErrorAction SilentlyContinue
    . (Join-Path $script:ProfileDir 'network-utils.ps1')
}

Describe 'profile.d/utilities-modules/network/utilities-network-advanced.ps1 extended scenarios' {
    It 'Registers advanced network helpers through network-utils.ps1' {
        Import-NetworkAdvancedModule

        Get-Command Invoke-WithRetry -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-HttpRequestWithRetry -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-NetworkConnectivity -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Resolve-HostWithRetry -ErrorAction Stop | Should -Not -BeNullOrEmpty
        $global:NetworkUtilsLoaded | Should -Be $true
    }

    It 'Invoke-WithRetry executes the supplied script block' {
        Import-NetworkAdvancedModule

        $result = Invoke-WithRetry -ScriptBlock { return 'network-retry-ok' }
        $result | Should -Be 'network-retry-ok'
    }

    It 'Skips re-initialization when advanced network utilities are already loaded' {
        Import-NetworkAdvancedModule
        $firstRetry = Get-Command Invoke-WithRetry -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'network-utils.ps1')

        (Get-Command Invoke-WithRetry -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstRetry.ScriptBlock.ToString()
    }
}
