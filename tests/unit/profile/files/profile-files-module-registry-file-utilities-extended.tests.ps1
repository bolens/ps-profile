# ===============================================
# profile-files-module-registry-file-utilities-extended.tests.ps1
# Execution tests for Ensure-FileUtilities registry entries
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

Describe 'profile.d/files-module-registry.ps1 Ensure-FileUtilities registry extended scenarios' {
    It 'Maps Ensure-FileUtilities to files-modules inspection and navigation entries' {
        $entries = $script:FileConversionModuleRegistry['Ensure-FileUtilities']
        ($entries | Where-Object { $_.Dir -like 'files-modules/*' }).Count | Should -Be 6
    }

    It 'Includes inspection and navigation utility modules' {
        $files = $script:FileConversionModuleRegistry['Ensure-FileUtilities'] | ForEach-Object { $_.File }
        $files | Should -Contain 'files-head-tail.ps1'
        $files | Should -Contain 'files-hash.ps1'
        $files | Should -Contain 'files-size.ps1'
        $files | Should -Contain 'files-hexdump.ps1'
        $files | Should -Contain 'files-listing.ps1'
        $files | Should -Contain 'files-navigation.ps1'
    }

    It 'Load-EnsureModules registers file utility commands from registry modules' {
        Load-EnsureModules -EnsureFunctionName 'Ensure-FileUtilities' -BaseDir $script:ProfileDir

        Get-Command Get-FileHead -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-FileHashValue -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Ensure-FileListing -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
