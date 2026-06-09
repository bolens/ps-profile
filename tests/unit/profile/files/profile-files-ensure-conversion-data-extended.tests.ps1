# ===============================================
# profile-files-ensure-conversion-data-extended.tests.ps1
# Execution tests for files.ps1 Ensure-FileConversion-Data behavior
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
    . (Join-Path $script:ProfileDir 'files.ps1')
}

function script:Reset-FileConversionDataState {
    Set-Variable -Name FileConversionDataInitialized -Scope Global -Value $false -Force
}

Describe 'profile.d/files.ps1 Ensure-FileConversion-Data extended scenarios' {
    BeforeEach {
        Reset-FileConversionDataState
    }

    It 'Registers data conversion helpers through Ensure-FileConversion-Data' {
        Ensure-FileConversion-Data

        Get-Command Format-Json -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ConvertTo-Yaml -ErrorAction Stop | Should -Not -BeNullOrEmpty
        $global:FileConversionDataInitialized | Should -Be $true
    }

    It 'Format-Json pretty-prints JSON input after Ensure-FileConversion-Data' {
        Ensure-FileConversion-Data
        $inputJson = (@{ name = 'ensure-data'; value = 42 } | ConvertTo-Json -Compress)
        $output = Format-Json -InputObject $inputJson

        $output | Should -Match 'name'
        $output | Should -Match 'ensure-data'
    }

    It 'Skips re-initialization when data conversion is already loaded' {
        Ensure-FileConversion-Data
        $firstJson = Get-Command Format-Json -ErrorAction Stop

        Ensure-FileConversion-Data

        (Get-Command Format-Json -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstJson.ScriptBlock.ToString()
    }
}
