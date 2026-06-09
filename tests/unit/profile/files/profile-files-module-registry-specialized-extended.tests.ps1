# ===============================================
# profile-files-module-registry-specialized-extended.tests.ps1
# Execution tests for Ensure-FileConversion-Specialized registry entries
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

Describe 'profile.d/files-module-registry.ps1 Ensure-FileConversion-Specialized registry extended scenarios' {
    It 'Maps Ensure-FileConversion-Specialized to the specialized loader module' {
        $entries = $script:FileConversionModuleRegistry['Ensure-FileConversion-Specialized']
        $entries.Count | Should -Be 1
        $entries[0].Dir | Should -Be 'conversion-modules/specialized'
        $entries[0].File | Should -Be 'specialized.ps1'
    }

    It 'Registers specialized conversion alongside media in the deferred loading map' {
        $script:FileConversionModuleRegistry.ContainsKey('Ensure-FileConversion-Media') | Should -Be $true
        $script:FileConversionModuleRegistry.ContainsKey('Ensure-FileConversion-Specialized') | Should -Be $true
    }

    It 'Load-EnsureModules loads specialized conversion submodule initializers' {
        Load-EnsureModules -EnsureFunctionName 'Ensure-FileConversion-Specialized' -BaseDir $script:ProfileDir

        Get-Command Initialize-FileConversion-Specialized -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-FileConversion-SpecializedQrCode -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-FileConversion-SpecializedJwt -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-FileConversion-SpecializedBarcode -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
