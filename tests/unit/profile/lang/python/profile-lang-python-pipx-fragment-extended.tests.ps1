# ===============================================
# profile-lang-python-pipx-fragment-extended.tests.ps1
# Execution tests for lang-python-pipx.ps1 fragment behavior
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

function script:Reset-LangPythonPipxFragmentState {
    Clear-FragmentLoaded -FragmentName 'lang-python-pipx' -ErrorAction SilentlyContinue
}

Describe 'profile.d/lang-python-pipx.ps1 extended scenarios' {
    BeforeEach {
        Reset-LangPythonPipxFragmentState
    }

    It 'Registers pipx helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'lang-python-pipx.ps1')

        Get-Command Install-PythonApp -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-Pipx -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'lang-python-pipx' | Should -Be $true
    }

    It 'Install-PythonApp warns when pipx is unavailable' {
        . (Join-Path $script:ProfileDir 'lang-python-pipx.ps1')

        Set-TestCommandAvailabilityState -CommandName 'pipx' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('pipx', [ref]$null)
        }

        $output = & { Install-PythonApp -Packages @('black') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'pipx not found'
    }

    It 'Skips re-initialization when lang-python-pipx is already loaded' {
        . (Join-Path $script:ProfileDir 'lang-python-pipx.ps1')
        $firstInstall = Get-Command Install-PythonApp -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'lang-python-pipx.ps1')

        (Get-Command Install-PythonApp -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstInstall.ScriptBlock.ToString()
    }
}
