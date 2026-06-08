# ===============================================
# profile-pip-fragment-extended.tests.ps1
# Execution tests for pip.ps1 fragment behavior
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

Describe 'profile.d/pip.ps1 extended scenarios' {
    It 'Registers pip package helpers when pip is available' {
        Set-TestCommandAvailabilityState -CommandName 'pip' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'pip.ps1')

        Get-Command Install-PipPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Remove-PipPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command pipinstall -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips pip helper registration when pip is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'pip' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'pip.ps1')

        Get-Command Install-PipPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Install-PipPackage warns when pip becomes unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'pip' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'pip.ps1')

        Set-TestCommandAvailabilityState -CommandName 'pip' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('pip', [ref]$null)
        }

        $output = Install-PipPackage 'requests' 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'pip not found'
    }
}
