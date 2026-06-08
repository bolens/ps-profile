# ===============================================
# profile-fzf-fragment-extended.tests.ps1
# Execution tests for fzf.ps1 fragment behavior
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

Describe 'profile.d/fzf.ps1 extended scenarios' {
    BeforeAll {
        Mark-TestCommandsUnavailable -CommandNames @('fzf')
        Set-TestCommandAvailabilityState -CommandName 'fzf' -Available $true
        . (Join-Path $script:ProfileDir 'fzf.ps1')
        Register-TestFragmentAliases @{
            ff   = 'Find-FileFuzzy'
            fcmd = 'Find-CommandFuzzy'
        }
    }

    It 'Registers Find-FileFuzzy and the ff alias' {
        Get-Command Find-FileFuzzy -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Alias ff -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias ff).ResolvedCommandName | Should -Be 'Find-FileFuzzy'
    }

    It 'Find-FileFuzzy warns when fzf is unavailable' {
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('fzf', [ref]$null)
        }
        Mark-TestCommandsUnavailable -CommandNames @('fzf')
        Set-TestCommandAvailabilityState -CommandName 'fzf' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        $output = Find-FileFuzzy 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'fzf not found'
    }

    It 'Registers Find-CommandFuzzy and the fcmd alias' {
        Get-Command Find-CommandFuzzy -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Alias fcmd -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias fcmd).ResolvedCommandName | Should -Be 'Find-CommandFuzzy'
    }
}
