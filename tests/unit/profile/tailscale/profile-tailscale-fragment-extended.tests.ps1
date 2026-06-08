# ===============================================
# profile-tailscale-fragment-extended.tests.ps1
# Execution tests for tailscale.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'tailscale.ps1')
}

Describe 'profile.d/tailscale.ps1 extended scenarios' {
    It 'Registers tailscale network helpers and aliases' {
        Get-Command Invoke-Tailscale -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-TailscaleStatus -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ts-status -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Tailscale warns when tailscale is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'tailscale' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('tailscale', [ref]$null)
        }

        $output = Invoke-Tailscale version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'tailscale not found'
    }

    It 'Preserves existing tailscale helper bodies on repeated fragment loads' {
        $firstTailscale = Get-Command Invoke-Tailscale -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'tailscale.ps1')

        (Get-Command Invoke-Tailscale -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstTailscale.ScriptBlock.ToString()
    }
}
