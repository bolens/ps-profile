# ===============================================
# profile-dust-fragment-extended.tests.ps1
# Execution tests for dust.ps1 fragment behavior
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
    Mark-TestCommandsUnavailable -CommandNames @('dust')
    Set-TestCommandAvailabilityState -CommandName 'dust' -Available $true
    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }
    . (Join-Path $script:ProfileDir 'dust.ps1')
}

Describe 'profile.d/dust.ps1 extended scenarios' {
    It 'Registers du alias targeting dust when dust is available' {
        Get-Alias du -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias du).Definition | Should -Be 'dust'
    }

    It 'Registers diskusage alias targeting dust' {
        Get-Alias diskusage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias diskusage).Definition | Should -Be 'dust'
    }

    It 'Warns when dust is unavailable during fragment load' {
        Mark-TestCommandsUnavailable -CommandNames @('dust')
        Set-TestCommandAvailabilityState -CommandName 'dust' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('dust', [ref]$null)
        }

        $output = & {
            . (Join-Path $script:ProfileDir 'dust.ps1') 2>&1 3>&1
        } | Out-String

        Assert-TestMissingToolWarning -Output $output -Pattern 'dust not found'
    }
}
