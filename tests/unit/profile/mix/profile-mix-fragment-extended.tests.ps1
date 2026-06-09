# ===============================================
# profile-mix-fragment-extended.tests.ps1
# Execution tests for mix.ps1 fragment behavior
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

Describe 'profile.d/mix.ps1 extended scenarios' {
    It 'Registers Mix helpers when mix is available' {
        Set-TestCommandAvailabilityState -CommandName 'mix' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'mix.ps1')

        Get-Command Test-MixOutdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Add-MixDependency -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command mix-outdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips Mix helper registration when mix is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'mix' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'mix.ps1')

        Get-Command Test-MixOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when mix is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'mix' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('mix', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'mix.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'mix not found'
    }
}
