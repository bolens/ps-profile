# ===============================================
# profile-files-module-registry-utilities-extended.tests.ps1
# Execution tests for Ensure-Utilities registry entries
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

Describe 'profile.d/files-module-registry.ps1 Ensure-Utilities registry extended scenarios' {
    It 'Maps Ensure-Utilities to utilities-modules entries' {
        $entries = $script:FileConversionModuleRegistry['Ensure-Utilities']
        ($entries | Where-Object { $_.Dir -like 'utilities-modules/*' }).Count | Should -BeGreaterThan 5
    }

    It 'Includes system network history and data utility modules' {
        $files = $script:FileConversionModuleRegistry['Ensure-Utilities'] | ForEach-Object { $_.File }
        $files | Should -Contain 'utilities-profile.ps1'
        $files | Should -Contain 'utilities-network.ps1'
        $files | Should -Contain 'utilities-history.ps1'
        $files | Should -Contain 'utilities-encoding.ps1'
        $files | Should -Contain 'utilities-datetime.ps1'
        $files | Should -Contain 'utilities-filesystem.ps1'
    }

    It 'Load-EnsureModules registers utilities helpers from registry modules' {
        Load-EnsureModules -EnsureFunctionName 'Ensure-Utilities' -BaseDir $script:ProfileDir

        Get-Command ConvertTo-UrlEncoded -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Find-History -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-SafePath -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
