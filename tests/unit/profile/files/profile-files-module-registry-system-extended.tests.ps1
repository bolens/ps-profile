# ===============================================
# profile-files-module-registry-system-extended.tests.ps1
# Execution tests for Ensure-System registry entries
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

Describe 'profile.d/files-module-registry.ps1 Ensure-System registry extended scenarios' {
    It 'Maps Ensure-System to system subdirectory modules' {
        $entries = $script:FileConversionModuleRegistry['Ensure-System']
        ($entries | Where-Object { $_.Dir -eq 'system' }).Count | Should -Be 6
    }

    It 'Includes file system archive and search modules in the registry' {
        $files = $script:FileConversionModuleRegistry['Ensure-System'] | ForEach-Object { $_.File }
        $files | Should -Contain 'FileOperations.ps1'
        $files | Should -Contain 'SystemInfo.ps1'
        $files | Should -Contain 'NetworkOperations.ps1'
        $files | Should -Contain 'ArchiveOperations.ps1'
        $files | Should -Contain 'EditorAliases.ps1'
        $files | Should -Contain 'TextSearch.ps1'
    }

    It 'Load-EnsureModules registers system helper commands' {
        Load-EnsureModules -EnsureFunctionName 'Ensure-System' -BaseDir $script:ProfileDir

        Get-Command Get-CommandInfo -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-DiskUsage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Find-String -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
