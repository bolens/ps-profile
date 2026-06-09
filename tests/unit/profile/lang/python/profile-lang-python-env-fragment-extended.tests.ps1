# ===============================================
# profile-lang-python-env-fragment-extended.tests.ps1
# Execution tests for lang-python-env.ps1 fragment behavior
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
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-LangPythonEnvFragmentState {
    Clear-FragmentLoaded -FragmentName 'lang-python-env' -ErrorAction SilentlyContinue
}

Describe 'profile.d/lang-python-env.ps1 extended scenarios' {
    BeforeEach {
        Reset-LangPythonEnvFragmentState
    }

    It 'Registers Python environment helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'lang-python-env.ps1')

        Get-Command Invoke-PythonScript -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command New-PythonVirtualEnv -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'lang-python-env' | Should -Be $true
    }

    It 'Invoke-PythonScript warns when python is unavailable' {
        . (Join-Path $script:ProfileDir 'lang-python-env.ps1')

        Set-TestCommandAvailabilityState -CommandName 'python3' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'python' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('python', [ref]$null)
        }

        $output = Invoke-PythonScript -Arguments @('-c', 'print(1)') 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'python not found'
    }

    It 'Skips re-initialization when lang-python-env is already loaded' {
        . (Join-Path $script:ProfileDir 'lang-python-env.ps1')
        $firstScript = Get-Command Invoke-PythonScript -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'lang-python-env.ps1')

        (Get-Command Invoke-PythonScript -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstScript.ScriptBlock.ToString()
    }
}
