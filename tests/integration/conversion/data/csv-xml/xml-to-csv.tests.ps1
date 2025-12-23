

<#
.SYNOPSIS
    Integration tests for XML to CSV conversion utilities.

.DESCRIPTION
    This test suite validates XML to CSV conversion functions.

.NOTES
    Tests cover XML to CSV conversions and related functionality.
#>

Describe 'XML to CSV Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'XML conversion utilities' {
        It 'ConvertFrom-XmlToJson converts XML to JSON' {
            $xml = '<root><item name="test" value="123"/></root>'
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value $xml
            $json = ConvertFrom-XmlToJson -Path $tempFile
            $json | Should -Not -BeNullOrEmpty
            $json | Should -Match 'root'
            $json | Should -Match 'item'
        }

        It 'ConvertFrom-XmlToJson handles complex XML structures' {
            $xml = '<users><user><name>alice</name><age>30</age></user><user><name>bob</name><age>25</age></user></users>'
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value $xml
            { ConvertFrom-XmlToJson -Path $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-XmlToJson and ConvertTo-CsvFromJson roundtrip via JSON' {
            $xml = '<root><item name="test" value="123"/></root>'
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value $xml
            $json = ConvertFrom-XmlToJson -Path $tempFile
            $jsonFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $jsonFile -Value $json
            { ConvertTo-CsvFromJson -Path $jsonFile } | Should -Not -Throw
        }
    }
}

