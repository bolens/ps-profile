# ===============================================
# profile-conda-fragment-extended.tests.ps1
# Execution tests for conda.ps1 fragment behavior
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

Describe 'profile.d/conda.ps1 extended scenarios' {
    It 'Registers conda helpers when conda is available' {
        Set-TestCommandAvailabilityState -CommandName 'conda' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'conda.ps1')

        Get-Command Install-CondaPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-CondaOutdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command conda-install -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips conda helper registration when conda is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'conda' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'conda.ps1')

        Get-Command Install-CondaPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when conda is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'conda' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('conda', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'conda.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'conda not found'
    }
}
