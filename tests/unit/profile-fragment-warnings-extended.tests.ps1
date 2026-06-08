<#
tests/unit/profile-fragment-warnings-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for fragment warning suppression helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $bootstrapDir 'GlobalState.ps1')
    . (Join-Path $bootstrapDir 'FragmentWarnings.ps1')
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS -ErrorAction SilentlyContinue
    Initialize-FragmentWarningSuppression
}

Describe 'FragmentWarnings extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS -ErrorAction SilentlyContinue
        $global:SuppressAllFragmentWarnings = $false
        if ($global:FragmentWarningPatternSet) {
            $global:FragmentWarningPatternSet.Clear()
        }
    }

    Context 'Initialize-FragmentWarningSuppression' {
        It 'Parses comma-separated fragment names from the environment' {
            $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS = '11-git,22-containers'

            Initialize-FragmentWarningSuppression

            Test-FragmentWarningSuppressed -FragmentName '11-git.ps1' | Should -Be $true
            Test-FragmentWarningSuppressed -FragmentName '22-containers.ps1' | Should -Be $true
            Test-FragmentWarningSuppressed -FragmentName '05-utilities.ps1' | Should -Be $false
        }

        It 'Enables global suppression for the all token' {
            $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS = 'all'

            Initialize-FragmentWarningSuppression

            $global:SuppressAllFragmentWarnings | Should -Be $true
            Test-FragmentWarningSuppressed -FragmentName 'any-fragment.ps1' | Should -Be $true
        }

        It 'Clears prior patterns when reinitialized with an empty value' {
            $env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS = '11-git'
            Initialize-FragmentWarningSuppression
            Test-FragmentWarningSuppressed -FragmentName '11-git.ps1' | Should -Be $true

            Remove-Item Env:\PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS -ErrorAction SilentlyContinue
            Initialize-FragmentWarningSuppression

            Test-FragmentWarningSuppressed -FragmentName '11-git.ps1' | Should -Be $false
        }
    }

    Context 'Test-FragmentWarningSuppressed' {
        It 'Matches basename patterns against full fragment paths' {
            $global:FragmentWarningPatternSet.Add('terminal-enhanced') | Out-Null

            Test-FragmentWarningSuppressed -FragmentName 'profile.d/terminal-enhanced.ps1' | Should -Be $true
        }

        It 'Returns false for blank fragment names' {
            $global:FragmentWarningPatternSet.Add('11-git') | Out-Null

            Test-FragmentWarningSuppressed -FragmentName '' | Should -Be $false
            Test-FragmentWarningSuppressed -FragmentName '   ' | Should -Be $false
        }

        It 'Supports wildcard pattern matching' {
            $global:FragmentWarningPatternSet.Add('*-git*') | Out-Null

            Test-FragmentWarningSuppressed -FragmentName '11-git.ps1' | Should -Be $true
        }
    }
}
