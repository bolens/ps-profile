# ===============================================
# profile-azure-fragment-extended.tests.ps1
# Execution tests for azure.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'azure.ps1')
}

Describe 'profile.d/azure.ps1 extended scenarios' {
    It 'Registers Invoke-Azure and Invoke-AzureDeveloper helpers' {
        Get-Command Invoke-Azure -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-AzureDeveloper -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Azure warns when az is unavailable' {
        Mark-TestCommandsUnavailable -CommandNames @('az')
        Set-TestCommandAvailabilityState -CommandName 'az' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('az', [ref]$null)
        }

        $output = Invoke-Azure --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'az not found'
    }

    It 'Invoke-AzureDeveloper warns when azd is unavailable' {
        Mark-TestCommandsUnavailable -CommandNames @('azd')
        Set-TestCommandAvailabilityState -CommandName 'azd' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('azd', [ref]$null)
        }

        $output = Invoke-AzureDeveloper --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'azd not found'
    }
}
