# ===============================================
# profile-hatch-fragment-extended.tests.ps1
# Execution tests for hatch.ps1 fragment behavior
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

Describe 'profile.d/hatch.ps1 extended scenarios' {
    It 'Registers hatch helpers when hatch is available' {
        Set-TestCommandAvailabilityState -CommandName 'hatch' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'hatch.ps1')

        Get-Command New-HatchEnvironment -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Build-HatchProject -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command hatchenv -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips hatch helper registration when hatch is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'hatch' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'hatch.ps1')

        Get-Command New-HatchEnvironment -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when hatch is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'hatch' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('hatch', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'hatch.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'hatch not found'
    }
}
