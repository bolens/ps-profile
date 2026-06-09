# ===============================================
# profile-files-module-registry-git-extended.tests.ps1
# Execution tests for Ensure-Git registry entries
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
}

Describe 'profile.d/files-module-registry.ps1 Ensure-Git registry extended scenarios' {
    It 'Maps Ensure-Git to git-modules entries' {
        $entries = $script:FileConversionModuleRegistry['Ensure-Git']
        ($entries | Where-Object { $_.Dir -like 'git-modules/core*' }).Count | Should -BeGreaterOrEqual 3
    }

    It 'Includes core git helper modules in the registry' {
        $files = $script:FileConversionModuleRegistry['Ensure-Git'] | ForEach-Object { $_.File }
        $files | Should -Contain 'git-helpers.ps1'
        $files | Should -Contain 'git-basic.ps1'
        $files | Should -Contain 'git-advanced.ps1'
        $files | Should -Contain 'git-github.ps1'
    }

    It 'Load-EnsureModules registers git command wrappers from core modules' {
        Load-EnsureModules -EnsureFunctionName 'Ensure-Git' -BaseDir $script:ProfileDir

        Get-Command Invoke-GitCommand -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-GitStatus -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command New-GitHubPullRequest -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
