# ===============================================
# profile-lazydocker-fragment-extended.tests.ps1
# Execution tests for lazydocker.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'lazydocker.ps1')
}

Describe 'profile.d/lazydocker.ps1 extended scenarios' {
    It 'Registers lazydocker helpers and aliases' {
        Get-Command Invoke-LazyDocker -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ld -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-LazyDocker warns when lazydocker is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'lazydocker' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('lazydocker', [ref]$null)
        }

        $output = Invoke-LazyDocker 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'lazydocker not found'
    }

    It 'Preserves existing lazydocker helper bodies on repeated fragment loads' {
        $firstLazyDocker = Get-Command Invoke-LazyDocker -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'lazydocker.ps1')

        (Get-Command Invoke-LazyDocker -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstLazyDocker.ScriptBlock.ToString()
    }
}
