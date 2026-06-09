# ===============================================
# profile-lang-python-packages-fragment-extended.tests.ps1
# Execution tests for lang-python-packages.ps1 fragment behavior
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

function script:Reset-LangPythonPackagesFragmentState {
    Clear-FragmentLoaded -FragmentName 'lang-python-packages' -ErrorAction SilentlyContinue
}

Describe 'profile.d/lang-python-packages.ps1 extended scenarios' {
    BeforeEach {
        Reset-LangPythonPackagesFragmentState
    }

    It 'Registers unified Python package installer and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'lang-python-packages.ps1')

        Get-Command Install-PythonPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command pyinstall -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'lang-python-packages' | Should -Be $true
    }

    It 'Install-PythonPackage warns when uv and pip are unavailable' {
        . (Join-Path $script:ProfileDir 'lang-python-packages.ps1')

        Set-TestCommandAvailabilityState -CommandName 'uv' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'pip' -Available $false
        Set-TestCommandAvailabilityState -CommandName 'pip3' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('pip', [ref]$null)
        }

        $output = & { Install-PythonPackage -Packages @('requests') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'pip not found'
    }

    It 'Skips re-initialization when lang-python-packages is already loaded' {
        . (Join-Path $script:ProfileDir 'lang-python-packages.ps1')
        $firstInstall = Get-Command Install-PythonPackage -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'lang-python-packages.ps1')

        (Get-Command Install-PythonPackage -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstInstall.ScriptBlock.ToString()
    }
}
