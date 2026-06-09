# ===============================================
# profile-bootstrap-fragment-warnings-extended.tests.ps1
# Execution tests for bootstrap/FragmentWarnings.ps1 behavior
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
    $script:BootstrapDir = Join-Path $script:ProfileDir 'bootstrap'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'profile.d/bootstrap/FragmentWarnings.ps1 extended scenarios' {
    It 'Registers fragment warning suppression helpers' {
        Get-Command Initialize-FragmentWarningSuppression -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-FragmentWarningSuppressed -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Test-FragmentWarningSuppressed honors PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS' {
        $previous = $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS
        try {
            $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS = 'git,aws'
            Initialize-FragmentWarningSuppression

            Test-FragmentWarningSuppressed -FragmentName 'git' | Should -Be $true
            Test-FragmentWarningSuppressed -FragmentName 'containers' | Should -Be $false
        }
        finally {
            if ($null -eq $previous) {
                Remove-Item Env:\PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS = $previous
            }
            Initialize-FragmentWarningSuppression
        }
    }

    It 'Preserves fragment warning helper bodies on repeated module loads' {
        $firstTest = Get-Command Test-FragmentWarningSuppressed -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'FragmentWarnings.ps1')

        (Get-Command Test-FragmentWarningSuppressed -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstTest.ScriptBlock.ToString()
    }
}
