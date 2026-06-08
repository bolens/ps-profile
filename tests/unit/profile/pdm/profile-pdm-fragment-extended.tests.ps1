# ===============================================
# profile-pdm-fragment-extended.tests.ps1
# Execution tests for pdm.ps1 fragment behavior
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
}

Describe 'profile.d/pdm.ps1 extended scenarios' {
    It 'Registers pdm helpers when pdm is available' {
        Set-TestCommandAvailabilityState -CommandName 'pdm' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'pdm.ps1')

        Get-Command Add-PdmPackage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Update-PdmPackages -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command pdmadd -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips pdm helper registration when pdm is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'pdm' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        . (Join-Path $script:ProfileDir 'pdm.ps1')

        Get-Command Add-PdmPackage -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'Emits missing-tool warning when pdm is unavailable at load time' {
        Set-TestCommandAvailabilityState -CommandName 'pdm' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('pdm', [ref]$null)
        }

        $output = & { . (Join-Path $script:ProfileDir 'pdm.ps1') } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'pdm not found'
    }
}
