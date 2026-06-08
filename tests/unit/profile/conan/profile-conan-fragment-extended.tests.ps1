# ===============================================
# profile-conan-fragment-extended.tests.ps1
# Execution tests for conan.ps1 fragment behavior
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

Describe 'profile.d/conan.ps1 extended scenarios' {
    It 'Registers conan helpers when conan is available' {
        Set-TestCommandAvailabilityState -CommandName 'conan' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'conan.ps1')

        Get-Command Install-ConanPackages -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Find-ConanPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command conaninstall -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips conan helper registration when conan is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'conan' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'conan.ps1')

        Get-Command Install-ConanPackages -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when conan is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'conan' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('conan', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'conan.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'conan not found'
    }
}
