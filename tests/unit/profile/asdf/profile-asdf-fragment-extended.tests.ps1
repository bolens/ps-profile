# ===============================================
# profile-asdf-fragment-extended.tests.ps1
# Execution tests for asdf.ps1 fragment behavior
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

Describe 'profile.d/asdf.ps1 extended scenarios' {
    It 'Registers asdf helpers when asdf is available' {
        Set-TestCommandAvailabilityState -CommandName 'asdf' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'asdf.ps1')

        Get-Command Install-AsdfTool -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-AsdfTools -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command asdfinstall -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips asdf helper registration when asdf is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'asdf' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'asdf.ps1')

        Get-Command Install-AsdfTool -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when asdf is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'asdf' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('asdf', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'asdf.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'asdf not found'
    }
}
