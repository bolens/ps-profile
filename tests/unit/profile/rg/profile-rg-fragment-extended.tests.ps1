# ===============================================
# profile-rg-fragment-extended.tests.ps1
# Execution tests for rg.ps1 fragment behavior
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

Describe 'profile.d/rg.ps1 extended scenarios' {
    BeforeAll {
        Mark-TestCommandsUnavailable -CommandNames @('rg')
        Set-TestCommandAvailabilityState -CommandName 'rg' -Available $true
        . (Join-Path $script:ProfileDir 'rg.ps1')
        Register-TestFragmentAliases @{
            rgf = 'Find-RipgrepText'
        }
    }

    It 'Registers Find-RipgrepText and the rgf alias' {
        Get-Command Find-RipgrepText -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Alias rgf -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias rgf).ResolvedCommandName | Should -Be 'Find-RipgrepText'
    }

    It 'Find-RipgrepText declares Pattern as a mandatory parameter' {
        $patternParameter = (Get-Command Find-RipgrepText -ErrorAction Stop).Parameters['Pattern']
        ($patternParameter.Attributes | Where-Object { $_ -is [Parameter] }).Mandatory | Should -Be $true
    }

    It 'Find-RipgrepText warns when rg is unavailable' {
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('rg', [ref]$null)
        }
        Mark-TestCommandsUnavailable -CommandNames @('rg')
        Set-TestCommandAvailabilityState -CommandName 'rg' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        $output = Find-RipgrepText -Pattern 'fragment probe' 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'rg not found'
    }
}
