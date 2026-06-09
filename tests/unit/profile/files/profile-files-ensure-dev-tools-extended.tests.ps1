# ===============================================
# profile-files-ensure-dev-tools-extended.tests.ps1
# Execution tests for files.ps1 Ensure-DevTools behavior
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
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'files.ps1')
}

function script:Reset-DevToolsState {
    Set-Variable -Name DevToolsInitialized -Scope Global -Value $false -Force
}

Describe 'profile.d/files.ps1 Ensure-DevTools extended scenarios' {
    BeforeEach {
        Reset-DevToolsState
    }

    It 'Registers dev tools helpers through Ensure-DevTools' {
        Ensure-DevTools

        Get-Command Get-TextHash -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command New-Uuid -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Convert-Units -ErrorAction Stop | Should -Not -BeNullOrEmpty
        $global:DevToolsInitialized | Should -Be $true
    }

    It 'Get-TextHash hashes text after Ensure-DevTools' {
        Ensure-DevTools
        $hash = Get-TextHash -Text 'dev-tools-ensure-test'

        $hash.Algorithm | Should -Be 'SHA256'
        $hash.Hash.Length | Should -Be 64
    }

    It 'Skips re-initialization when dev tools are already loaded' {
        Ensure-DevTools
        $firstHash = Get-Command Get-TextHash -ErrorAction Stop

        Ensure-DevTools

        (Get-Command Get-TextHash -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstHash.ScriptBlock.ToString()
    }
}
