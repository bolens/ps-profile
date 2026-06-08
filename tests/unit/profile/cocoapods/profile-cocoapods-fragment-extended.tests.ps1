# ===============================================
# profile-cocoapods-fragment-extended.tests.ps1
# Execution tests for cocoapods.ps1 fragment behavior
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

Describe 'profile.d/cocoapods.ps1 extended scenarios' {
    It 'Registers CocoaPods helpers when pod is available' {
        Set-TestCommandAvailabilityState -CommandName 'pod' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'cocoapods.ps1')

        Get-Command Install-CocoaPodsDependencies -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Update-CocoaPodsDependencies -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command podinstall -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips CocoaPods helper registration when pod is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'pod' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'cocoapods.ps1')

        Get-Command Install-CocoaPodsDependencies -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when pod is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'pod' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('cocoapods', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'cocoapods.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'pod not found'
    }
}
