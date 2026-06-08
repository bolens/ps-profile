# ===============================================
# profile-poetry-fragment-extended.tests.ps1
# Execution tests for poetry.ps1 fragment behavior
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

Describe 'profile.d/poetry.ps1 extended scenarios' {
    It 'Registers poetry helpers when poetry is available' {
        Set-TestCommandAvailabilityState -CommandName 'poetry' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'poetry.ps1')

        Get-Command Install-PoetryDependencies -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-PoetryOutdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command poetry-add -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips poetry helper registration when poetry is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'poetry' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'poetry.ps1')

        Get-Command Install-PoetryDependencies -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when poetry is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'poetry' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('poetry', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'poetry.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'poetry not found'
    }
}
