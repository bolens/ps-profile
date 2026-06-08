# ===============================================
# profile-containers-fragment-extended.tests.ps1
# Execution tests for containers.ps1 fragment behavior
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

    $importCommand = Get-Command Import-FragmentModules -ErrorAction SilentlyContinue
    $script:TestImportFragmentModulesBody = if ($importCommand) { $importCommand.ScriptBlock } else { $null }
}

Describe 'profile.d/containers.ps1 extended scenarios' {
    BeforeEach {
        if ($script:TestImportFragmentModulesBody) {
            Set-Item -Path Function:\Import-FragmentModules -Value $script:TestImportFragmentModulesBody -Force
        }
    }

    It 'Loads container helper and compose commands through Import-FragmentModules' {
        . (Join-Path $script:ProfileDir 'containers.ps1')

        Get-Command Get-ContainerEnginePreference -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Start-ContainerCompose -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Stop-ContainerCompose -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Keeps compose helpers available after repeated fragment loads' {
        . (Join-Path $script:ProfileDir 'containers.ps1')
        $firstCompose = Get-Command Start-ContainerCompose -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'containers.ps1')

        (Get-Command Start-ContainerCompose -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstCompose.ScriptBlock.ToString()
    }
}
