# ===============================================
# profile-yarn-fragment-extended.tests.ps1
# Execution tests for yarn.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'yarn.ps1')
}

Describe 'profile.d/yarn.ps1 extended scenarios' {
    It 'Registers yarn package manager helpers and aliases' {
        Get-Command Invoke-Yarn -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Add-YarnPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command yarn -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Yarn warns when yarn is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'yarn' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('yarn', [ref]$null)
        }

        $output = Invoke-Yarn --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'yarn not found'
    }

    It 'Preserves existing yarn helper bodies on repeated fragment loads' {
        $firstYarn = Get-Command Invoke-Yarn -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'yarn.ps1')

        (Get-Command Invoke-Yarn -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstYarn.ScriptBlock.ToString()
    }
}
