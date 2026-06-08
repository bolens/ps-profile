# ===============================================
# profile-starship-fragment-extended.tests.ps1
# Execution tests for starship.ps1 fragment behavior
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
    Mark-TestCommandsUnavailable -CommandNames @('starship')
    Set-TestCommandAvailabilityState -CommandName 'starship' -Available $false

    $importCommand = Get-Command Import-FragmentModules -ErrorAction SilentlyContinue
    $script:TestImportFragmentModulesBody = if ($importCommand) { $importCommand.ScriptBlock } else { $null }
}

Describe 'profile.d/starship.ps1 extended scenarios' {
    BeforeEach {
        if ($script:TestImportFragmentModulesBody) {
            Set-Item -Path Function:\Import-FragmentModules -Value $script:TestImportFragmentModulesBody -Force
        }
    }

    It 'Creates Initialize-Starship and loads helper modules through Import-FragmentModules' {
        . (Join-Path $script:ProfileDir 'starship.ps1')

        Get-Command Initialize-Starship -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-SmartPrompt -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-StarshipInitialized -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Initialize-Starship executes without error when starship is unavailable' {
        . (Join-Path $script:ProfileDir 'starship.ps1')

        { Initialize-Starship } | Should -Not -Throw
    }

}
