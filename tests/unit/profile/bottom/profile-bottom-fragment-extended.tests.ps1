# ===============================================
# profile-bottom-fragment-extended.tests.ps1
# Execution tests for bottom.ps1 fragment behavior
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
    Mark-TestCommandsUnavailable -CommandNames @('btm', 'bottom')
    Set-TestCommandAvailabilityState -CommandName 'btm' -Available $true
    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }
    . (Join-Path $script:ProfileDir 'bottom.ps1')
}

Describe 'profile.d/bottom.ps1 extended scenarios' {
    It 'Registers top alias targeting bottom when btm is available' {
        Get-Alias top -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias top).Definition | Should -Be 'btm'
    }

    It 'Registers htop and monitor aliases targeting bottom' {
        Get-Alias htop -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias htop).Definition | Should -Be 'btm'
        Get-Alias monitor -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias monitor).Definition | Should -Be 'btm'
    }

    It 'Prefers btm over bottom when both commands are available' {
        Set-TestCommandAvailabilityState -CommandName 'bottom' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'bottom.ps1')

        (Get-Alias top).Definition | Should -Be 'btm'
    }
}
