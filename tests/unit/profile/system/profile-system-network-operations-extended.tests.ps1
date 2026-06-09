# ===============================================
# profile-system-network-operations-extended.tests.ps1
# Execution tests for system/NetworkOperations.ps1 behavior
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
    . (Join-Path $script:ProfileDir 'system.ps1')
}

function script:Reset-SystemFragmentState {
    Set-Variable -Name 'SystemInitialized' -Scope Global -Value $false -Force
}

Describe 'profile.d/system/NetworkOperations.ps1 extended scenarios' {
    BeforeEach {
        Reset-SystemFragmentState
        Ensure-System
    }

    It 'Registers network helper commands through Ensure-System' {
        Get-Command Get-NetworkPorts -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-NetworkConnection -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Resolve-DnsNameCustom -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-RestApi -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $portsAlias = Get-Alias ports -ErrorAction SilentlyContinue
        if ($portsAlias) {
            $portsAlias.ResolvedCommandName | Should -Be 'Get-NetworkPorts'
        }
    }

    It 'Get-NetworkPorts invokes netstat when the command is available' {
        Set-TestCommandAvailabilityState -CommandName 'netstat' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        { Get-NetworkPorts | Out-Null } | Should -Not -Throw
    }

    It 'Get-NetworkPorts throws when netstat is unavailable' {
        Mark-TestCommandsUnavailable -CommandNames @('netstat')
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        { Get-NetworkPorts | Out-Null } | Should -Throw '*netstat*'
    }
}
