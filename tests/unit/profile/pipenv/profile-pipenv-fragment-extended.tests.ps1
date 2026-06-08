# ===============================================
# profile-pipenv-fragment-extended.tests.ps1
# Execution tests for pipenv.ps1 fragment behavior
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

Describe 'profile.d/pipenv.ps1 extended scenarios' {
    It 'Registers pipenv helpers when pipenv is available' {
        Set-TestCommandAvailabilityState -CommandName 'pipenv' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'pipenv.ps1')

        Get-Command Install-PipenvPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Remove-PipenvPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command pipenvadd -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips pipenv helper registration when pipenv is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'pipenv' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'pipenv.ps1')

        Get-Command Install-PipenvPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when pipenv is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'pipenv' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('pipenv', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'pipenv.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'pipenv not found'
    }
}
