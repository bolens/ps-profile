# ===============================================
# profile-diagnostics-fragment-extended.tests.ps1
# Execution tests for diagnostics.ps1 fragment behavior
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
    $script:SavedDebug = $env:PS_PROFILE_DEBUG
    $env:PS_PROFILE_DEBUG = '1'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')

    $importCommand = Get-Command Import-FragmentModule -ErrorAction SilentlyContinue
    $script:TestImportFragmentModuleBody = if ($importCommand) { $importCommand.ScriptBlock } else { $null }
}

AfterAll {
    $env:PS_PROFILE_DEBUG = $script:SavedDebug
}

function script:Reset-DiagnosticsFragmentState {
    Remove-Variable -Name 'PSProfileDiagnosticsLoaded' -Scope Global -ErrorAction SilentlyContinue
    foreach ($commandName in @(
            'Show-ProfileDiagnostic'
            'Show-ProfileStartupTime'
            'Test-ProfileHealth'
            'Show-CommandUsageStats'
        )) {
        Remove-Item -Path "Function:\$commandName" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:$commandName" -Force -ErrorAction SilentlyContinue
    }
}

Describe 'profile.d/diagnostics.ps1 extended scenarios' {
    BeforeEach {
        if ($script:TestImportFragmentModuleBody) {
            Set-Item -Path Function:\Import-FragmentModule -Value $script:TestImportFragmentModuleBody -Force
        }

        Reset-DiagnosticsFragmentState
    }

    It 'Registers diagnostic commands when PS_PROFILE_DEBUG is set during load' {
        . (Join-Path $script:ProfileDir 'diagnostics.ps1')

        Get-Command Test-ProfileHealth -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Show-ProfileDiagnostic -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Show-ProfileStartupTime -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Variable -Name 'PSProfileDiagnosticsLoaded' -Scope Global -ErrorAction Stop).Value | Should -Be $true
    }

    It 'Skips re-initialization when diagnostics commands remain registered' {
        . (Join-Path $script:ProfileDir 'diagnostics.ps1')
        $firstHealth = Get-Command Test-ProfileHealth -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'diagnostics.ps1')

        (Get-Command Test-ProfileHealth -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstHealth.ScriptBlock.ToString()
    }
}
