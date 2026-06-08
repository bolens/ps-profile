# ===============================================
# profile-php-fragment-extended.tests.ps1
# Execution tests for php.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'php.ps1')
}

Describe 'profile.d/php.ps1 extended scenarios' {
    It 'Registers PHP and Composer helpers and aliases' {
        Get-Command Invoke-Php -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-Composer -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command php -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Php warns when php is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'php' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('php', [ref]$null)
        }

        $output = Invoke-Php --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'php not found'
    }

    It 'Preserves existing php helper bodies on repeated fragment loads' {
        $firstPhp = Get-Command Invoke-Php -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'php.ps1')

        (Get-Command Invoke-Php -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstPhp.ScriptBlock.ToString()
    }
}
