# ===============================================
# profile-files-registry-loader-extended.tests.ps1
# Execution tests for files.ps1 registry loader behavior
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

function script:Reset-FilesFragmentState {
    foreach ($flagName in @(
            'FileUtilitiesInitialized'
            'FileConversionDataInitialized'
            'FileConversionDocumentsInitialized'
            'FileConversionMediaInitialized'
            'FileConversionSpecializedInitialized'
            'DevToolsInitialized'
        )) {
        Set-Variable -Name $flagName -Scope Global -Value $false -Force
    }
}

Describe 'profile.d/files.ps1 files-module-registry loader extended scenarios' {
    BeforeEach {
        Reset-FilesFragmentState
    }

    It 'Loads files-module-registry and registers Ensure-FileUtilities' {
        . (Join-Path $script:ProfileDir 'files.ps1')

        Get-Command Ensure-FileUtilities -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Ensure-FileConversion-Data -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Ensure-FileConversion-Documents -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Registers LaTeX detection helpers through files.ps1' {
        . (Join-Path $script:ProfileDir 'files.ps1')

        Get-Command Test-DocumentLatexEngineAvailable -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Ensure-DocumentLatexEngine -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Allows repeated Ensure-FileUtilities calls without losing commands' {
        . (Join-Path $script:ProfileDir 'files.ps1')

        Ensure-FileUtilities
        Ensure-FileUtilities

        Get-Command Get-FileHashValue -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-FileSize -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
