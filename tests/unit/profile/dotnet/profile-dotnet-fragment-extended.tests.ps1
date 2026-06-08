# ===============================================
# profile-dotnet-fragment-extended.tests.ps1
# Execution tests for dotnet.ps1 fragment behavior
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

Describe 'profile.d/dotnet.ps1 extended scenarios' {
    It 'Registers dotnet helpers when dotnet is available' {
        Set-TestCommandAvailabilityState -CommandName 'dotnet' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'dotnet.ps1')

        Get-Command Test-DotnetOutdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Add-DotnetPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command dotnet-outdated -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips dotnet helper registration when dotnet is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'dotnet' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'dotnet.ps1')

        Get-Command Test-DotnetOutdated -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when dotnet is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'dotnet' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('dotnet', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'dotnet.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'dotnet not found'
    }
}
