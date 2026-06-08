# ===============================================
# profile-volta-fragment-extended.tests.ps1
# Execution tests for volta.ps1 fragment behavior
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

Describe 'profile.d/volta.ps1 extended scenarios' {
    It 'Registers volta helpers when volta is available' {
        Set-TestCommandAvailabilityState -CommandName 'volta' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'volta.ps1')

        Get-Command Install-VoltaTool -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-VoltaTools -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command voltainstall -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips volta helper registration when volta is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'volta' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'volta.ps1')

        Get-Command Install-VoltaTool -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when volta is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'volta' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('volta', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'volta.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'volta not found'
    }
}
