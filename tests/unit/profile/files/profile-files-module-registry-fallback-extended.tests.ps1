# ===============================================
# profile-files-module-registry-fallback-extended.tests.ps1
# Execution tests for files-module-registry.ps1 fallback and edge cases
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

Describe 'profile.d/files-module-registry.ps1 registry fallback extended scenarios' {
    It 'Returns early when registry key is missing' {
        { Load-EnsureModules -EnsureFunctionName 'Ensure-Nonexistent' -BaseDir $script:ProfileDir } | Should -Not -Throw
    }

    It 'Load-EnsureModules loads all file utility registry modules' {
        Load-EnsureModules -EnsureFunctionName 'Ensure-FileUtilities' -BaseDir $script:ProfileDir

        @($script:FileConversionModuleRegistry['Ensure-FileUtilities']).Count | Should -Be 6
        Get-Command Get-FileHead -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Ensure-FileListing -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Splits registry Dir paths into module path segments for Import-FragmentModule' {
        $entry = $script:FileConversionModuleRegistry['Ensure-FileUtilities'] |
            Where-Object { $_.File -eq 'files-hash.ps1' } |
            Select-Object -First 1

        $entry.Dir | Should -Be 'files-modules/inspection'
        $entry.File | Should -Be 'files-hash.ps1'
    }
}
