# ===============================================
# profile-mojo-fragment-extended.tests.ps1
# Execution tests for mojo.ps1 fragment behavior
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

Describe 'profile.d/mojo.ps1 extended scenarios' {
    It 'Registers Mojo helpers when mojo is available' {
        Set-TestCommandAvailabilityState -CommandName 'mojo' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'mojo.ps1')

        Get-Command Invoke-MojoRun -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Build-MojoProgram -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command mojo-run -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips Mojo helper registration when mojo is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'mojo' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'mojo.ps1')

        Get-Command Invoke-MojoRun -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when mojo is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'mojo' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('mojo', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'mojo.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'mojo not found'
    }
}
