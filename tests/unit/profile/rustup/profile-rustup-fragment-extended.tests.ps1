# ===============================================
# profile-rustup-fragment-extended.tests.ps1
# Execution tests for rustup.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'rustup.ps1')
}

Describe 'profile.d/rustup.ps1 extended scenarios' {
    It 'Registers rustup and cargo helper aliases' {
        Get-Command Invoke-Rustup -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Update-RustupToolchain -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command rustup -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Rustup warns when rustup is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'rustup' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('rustup', [ref]$null)
        }

        $output = Invoke-Rustup --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'rustup not found'
    }

    It 'Preserves existing rustup helper bodies on repeated fragment loads' {
        $firstRustup = Get-Command Invoke-Rustup -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'rustup.ps1')

        (Get-Command Invoke-Rustup -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstRustup.ScriptBlock.ToString()
    }
}
