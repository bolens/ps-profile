# ===============================================
# profile-files-module-registry-data-extended.tests.ps1
# Execution tests for Ensure-FileConversion-Data registry entries
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

Describe 'profile.d/files-module-registry.ps1 Ensure-FileConversion-Data registry extended scenarios' {
    It 'Maps Ensure-FileConversion-Data to conversion-modules/data entries' {
        $entries = $script:FileConversionModuleRegistry['Ensure-FileConversion-Data']
        ($entries | Where-Object { $_.Dir -like 'conversion-modules/data/*' }).Count | Should -BeGreaterThan 10
    }

    It 'Includes core helper and scientific modules in the data registry' {
        $files = $script:FileConversionModuleRegistry['Ensure-FileConversion-Data'] | ForEach-Object { $_.File }
        $files | Should -Contain 'ConversionBase.ps1'
        $files | Should -Contain 'helpers-xml.ps1'
        $files | Should -Contain 'csv.ps1'
        $files | Should -Contain 'scientific-hdf5.ps1'
        $files | Should -Contain 'database-sqlite.ps1'
        $files | Should -Contain 'network-url-uri.ps1'
    }

    It 'Load-EnsureModules loads data conversion module initializers' {
        Load-EnsureModules -EnsureFunctionName 'Ensure-FileConversion-Data' -BaseDir $script:ProfileDir

        Get-Command Initialize-FileConversion-CoreBasicJson -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-FileConversion-ColumnarParquet -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-FileConversion-ScientificHdf5 -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
