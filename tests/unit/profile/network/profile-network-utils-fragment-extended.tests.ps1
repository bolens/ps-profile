# ===============================================
# profile-network-utils-fragment-extended.tests.ps1
# Execution tests for network-utils.ps1 fragment behavior
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
}

function script:Reset-NetworkUtilsFragmentState {
    Remove-Variable -Name 'NetworkUtilsLoaded' -Scope Global -ErrorAction SilentlyContinue
}

Describe 'profile.d/network-utils.ps1 extended scenarios' {
    BeforeEach {
        Reset-NetworkUtilsFragmentState
    }

    It 'Loads advanced network utility commands from utilities-network-advanced module' {
        . (Join-Path $script:ProfileDir 'network-utils.ps1')

        Get-Command Test-NetworkConnectivity -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-HttpRequestWithRetry -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Resolve-HostWithRetry -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Variable -Name 'NetworkUtilsLoaded' -Scope Global -ErrorAction Stop).Value | Should -Be $true
    }

    It 'Invoke-WithRetry executes without error for a simple script block' {
        . (Join-Path $script:ProfileDir 'network-utils.ps1')

        $result = Invoke-WithRetry -ScriptBlock { 'network-utils probe' } -MaxRetries 1
        $result | Should -Be 'network-utils probe'
    }

    It 'Skips re-initialization when network utilities are already loaded' {
        . (Join-Path $script:ProfileDir 'network-utils.ps1')
        $firstConnectivity = Get-Command Test-NetworkConnectivity -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'network-utils.ps1')

        (Get-Command Test-NetworkConnectivity -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstConnectivity.ScriptBlock.ToString()
    }
}
