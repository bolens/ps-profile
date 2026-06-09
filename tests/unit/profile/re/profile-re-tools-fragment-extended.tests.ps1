# ===============================================
# profile-re-tools-fragment-extended.tests.ps1
# Execution tests for re-tools.ps1 fragment behavior
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

function script:Reset-ReToolsFragmentState {
    Clear-FragmentLoaded -FragmentName 're-tools' -ErrorAction SilentlyContinue
}

Describe 'profile.d/re-tools.ps1 extended scenarios' {
    BeforeEach {
        Reset-ReToolsFragmentState
    }

    It 'Registers reverse engineering helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 're-tools.ps1')

        Get-Command Decompile-Java -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Analyze-PE -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 're-tools' | Should -Be $true
    }

    It 'Decompile-Java warns when jadx is unavailable' {
        . (Join-Path $script:ProfileDir 're-tools.ps1')

        Set-TestCommandAvailabilityState -CommandName 'jadx' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('jadx', [ref]$null)
        }

        $output = & { Decompile-Java -InputFile 'test.dex' } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'jadx not found'
    }

    It 'Skips re-initialization when re-tools is already loaded' {
        . (Join-Path $script:ProfileDir 're-tools.ps1')
        $firstDecompile = Get-Command Decompile-Java -ErrorAction Stop

        . (Join-Path $script:ProfileDir 're-tools.ps1')

        (Get-Command Decompile-Java -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstDecompile.ScriptBlock.ToString()
    }
}
