# ===============================================
# profile-rye-fragment-extended.tests.ps1
# Execution tests for rye.ps1 fragment behavior
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

Describe 'profile.d/rye.ps1 extended scenarios' {
    It 'Registers rye helpers when rye is available' {
        Set-TestCommandAvailabilityState -CommandName 'rye' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'rye.ps1')

        Get-Command Add-RyePackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Sync-RyeDependencies -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ryeadd -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips rye helper registration when rye is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'rye' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'rye.ps1')

        Get-Command Add-RyePackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when rye is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'rye' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('rye', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'rye.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'rye not found'
    }
}
