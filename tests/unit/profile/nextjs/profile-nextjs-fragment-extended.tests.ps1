# ===============================================
# profile-nextjs-fragment-extended.tests.ps1
# Execution tests for nextjs.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'nextjs.ps1')
}

Describe 'profile.d/nextjs.ps1 extended scenarios' {
    It 'Registers Next.js dev helpers and aliases' {
        Get-Command Start-NextJsDev -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command New-NextJsApp -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command next-dev -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Start-NextJsDev warns when npx is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'npx' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('npm', [ref]$null)
        }

        $output = Start-NextJsDev 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'npx not found'
    }

    It 'Preserves existing nextjs helper bodies on repeated fragment loads' {
        $firstDev = Get-Command Start-NextJsDev -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'nextjs.ps1')

        (Get-Command Start-NextJsDev -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstDev.ScriptBlock.ToString()
    }
}
