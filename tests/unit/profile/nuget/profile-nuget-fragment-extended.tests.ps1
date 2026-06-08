# ===============================================
# profile-nuget-fragment-extended.tests.ps1
# Execution tests for nuget.ps1 fragment behavior
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

Describe 'profile.d/nuget.ps1 extended scenarios' {
    It 'Registers nuget helpers when nuget is available' {
        Set-TestCommandAvailabilityState -CommandName 'nuget' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'nuget.ps1')

        Get-Command Install-NuGetPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Restore-NuGetPackages -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command nugetinstall -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips nuget helper registration when nuget is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'nuget' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'nuget.ps1')

        Get-Command Install-NuGetPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when nuget is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'nuget' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('nuget', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'nuget.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'nuget not found'
    }
}
