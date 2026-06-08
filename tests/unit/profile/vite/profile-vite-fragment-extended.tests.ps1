# ===============================================
# profile-vite-fragment-extended.tests.ps1
# Execution tests for vite.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'vite.ps1')
}

Describe 'profile.d/vite.ps1 extended scenarios' {
    It 'Registers Vite dev helpers and aliases' {
        Get-Command Invoke-Vite -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Start-ViteDev -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command vite -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Vite warns when vite is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'vite' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('vite', [ref]$null)
        }

        $output = Invoke-Vite --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'vite not found'
    }

    It 'Preserves existing vite helper bodies on repeated fragment loads' {
        $firstVite = Get-Command Invoke-Vite -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'vite.ps1')

        (Get-Command Invoke-Vite -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstVite.ScriptBlock.ToString()
    }
}
