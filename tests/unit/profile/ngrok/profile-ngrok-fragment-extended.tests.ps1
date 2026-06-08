# ===============================================
# profile-ngrok-fragment-extended.tests.ps1
# Execution tests for ngrok.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'ngrok.ps1')
}

Describe 'profile.d/ngrok.ps1 extended scenarios' {
    It 'Registers ngrok tunnel helpers and aliases' {
        Get-Command Invoke-Ngrok -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Start-NgrokHttpTunnel -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ngrok -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Ngrok warns when ngrok is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'ngrok' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('ngrok', [ref]$null)
        }

        $output = Invoke-Ngrok version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'ngrok not found'
    }

    It 'Preserves existing ngrok helper bodies on repeated fragment loads' {
        $firstNgrok = Get-Command Invoke-Ngrok -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'ngrok.ps1')

        (Get-Command Invoke-Ngrok -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstNgrok.ScriptBlock.ToString()
    }
}
