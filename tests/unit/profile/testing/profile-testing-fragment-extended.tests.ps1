# ===============================================
# profile-testing-fragment-extended.tests.ps1
# Execution tests for testing.ps1 fragment behavior
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

    $importCommand = Get-Command Import-FragmentModule -ErrorAction SilentlyContinue
    $script:TestImportFragmentModuleBody = if ($importCommand) { $importCommand.ScriptBlock } else { $null }
}

Describe 'profile.d/testing.ps1 extended scenarios' {
    BeforeEach {
        if ($script:TestImportFragmentModuleBody) {
            Set-Item -Path Function:\Import-FragmentModule -Value $script:TestImportFragmentModuleBody -Force
        }
    }

    It 'Loads testing framework helpers through Import-FragmentModule' {
        . (Join-Path $script:ProfileDir 'testing.ps1')

        Get-Command Invoke-Jest -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-Vitest -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-Playwright -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Jest warns when jest is unavailable' {
        . (Join-Path $script:ProfileDir 'testing.ps1')

        Mark-TestCommandsUnavailable -CommandNames @('jest', 'npx')
        Set-TestCommandAvailabilityState -CommandName 'jest' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'npx' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('jest', [ref]$null)
        }

        $output = Invoke-Jest 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'jest or npx not found'
    }
}
