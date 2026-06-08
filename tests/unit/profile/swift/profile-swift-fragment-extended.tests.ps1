# ===============================================
# profile-swift-fragment-extended.tests.ps1
# Execution tests for swift.ps1 fragment behavior
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

Describe 'profile.d/swift.ps1 extended scenarios' {
    It 'Registers Swift package helpers when swift is available' {
        Set-TestCommandAvailabilityState -CommandName 'swift' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'swift.ps1')

        Get-Command Add-SwiftPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Update-SwiftPackages -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command swift-add -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips Swift helper registration when swift is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'swift' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'swift.ps1')

        Get-Command Add-SwiftPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when swift is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'swift' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('swift', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'swift.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'swift not found'
    }
}
