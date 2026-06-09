# ===============================================
# profile-vcpkg-fragment-extended.tests.ps1
# Execution tests for vcpkg.ps1 fragment behavior
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

Describe 'profile.d/vcpkg.ps1 extended scenarios' {
    It 'Registers vcpkg helpers when vcpkg is available' {
        Set-TestCommandAvailabilityState -CommandName 'vcpkg' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'vcpkg.ps1')

        Get-Command Install-VcpkgPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Update-VcpkgPackages -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command vcpkginstall -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips vcpkg helper registration when vcpkg is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'vcpkg' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'vcpkg.ps1')

        Get-Command Install-VcpkgPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when vcpkg is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'vcpkg' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('vcpkg', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'vcpkg.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'vcpkg not found'
    }
}
