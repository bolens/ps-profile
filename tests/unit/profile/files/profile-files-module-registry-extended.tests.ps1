# ===============================================
# profile-files-module-registry-extended.tests.ps1
# Execution tests for files-module-registry.ps1 core registry behavior
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

Describe 'profile.d/files-module-registry.ps1 extended scenarios' {
    It 'Exposes FileConversionModuleRegistry with core Ensure function keys' {
        $script:FileConversionModuleRegistry.Keys | Should -Contain 'Ensure-FileUtilities'
        $script:FileConversionModuleRegistry.Keys | Should -Contain 'Ensure-FileConversion-Data'
        $script:FileConversionModuleRegistry.Keys | Should -Contain 'Ensure-DevTools'
    }

    It 'Load-EnsureModules loads file inspection module initializers' {
        Load-EnsureModules -EnsureFunctionName 'Ensure-FileUtilities' -BaseDir $script:ProfileDir

        Get-Command Initialize-FileUtilities-Hash -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-FileUtilities-Size -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-FileHashValue -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Lists ConversionBase before data format modules in the data registry' {
        $entries = $script:FileConversionModuleRegistry['Ensure-FileConversion-Data']
        ($entries | Select-Object -First 1).File | Should -Be 'ConversionBase.ps1'
        ($entries | Where-Object { $_.Dir -like 'conversion-modules/helpers*' }).Count | Should -BeGreaterThan 0
    }
}
