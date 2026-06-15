# ===============================================
# profile-bootstrap-global-state-extended.tests.ps1
# Execution tests for bootstrap/GlobalState.ps1 behavior
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

Describe 'profile.d/bootstrap/GlobalState.ps1 extended scenarios' {
    It 'Initializes core bootstrap global registries' {
        $global:TestCachedCommandCache | Should -Not -BeNullOrEmpty
        $global:AssumedAvailableCommands | Should -Not -BeNullOrEmpty
        Get-Command Test-EnvBool -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-ProfileDebugLevel -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Test-EnvBool and Get-ProfileDebugLevel parse environment values' {
        try {
        Test-EnvBool -Value 'true' | Should -Be $true
        Test-EnvBool -Value '0' | Should -Be $false

        $previousDebug = $env:PS_PROFILE_DEBUG
                $env:PS_PROFILE_DEBUG = '2'
        Get-ProfileDebugLevel | Should -Be 2
        }
        finally {
            if ($null -eq $previousDebug) {
                Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $previousDebug
            }
        }
    }

    It 'Preserves global state helper bodies on repeated module loads' {
        $firstEnvBool = Get-Command Test-EnvBool -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'GlobalState.ps1')

        (Get-Command Test-EnvBool -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstEnvBool.ScriptBlock.ToString()
    }
}
