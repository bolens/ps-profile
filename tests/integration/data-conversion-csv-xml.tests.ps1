. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

<#
.SYNOPSIS
    Integration tests for CSV and XML conversion utilities.

.DESCRIPTION
    This test suite validates CSV and XML conversion functions including
    conversions to/from JSON and YAML formats.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'CSV and XML Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files.ps1')
        Ensure-FileConversion-Data
    }

    Context 'CSV conversion utilities' {
        It 'ConvertFrom-CsvToJson converts CSV to JSON' {
            $csv = "name,value`nalice,123`nbob,456"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $csv
            $json = ConvertFrom-CsvToJson -Path $tempFile
            $json | Should -Not -BeNullOrEmpty
            $json | Should -Match '"name":\s*"alice"'
            $json | Should -Match '"value":\s*"123"'
        }

        It 'ConvertFrom-CsvToJson handles quoted fields' {
            $csv = '"name","description"|"John Doe","Software Engineer"'
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $csv
            { ConvertFrom-CsvToJson -Path $tempFile } | Should -Not -Throw
        }

        It 'ConvertTo-CsvFromJson converts JSON to CSV' {
            $json = '[{"name": "alice", "value": 123}, {"name": "bob", "value": 456}]'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            { ConvertTo-CsvFromJson -Path $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-CsvToJson and ConvertTo-CsvFromJson roundtrip' {
            $originalCsv = "name,value`nalice,123`nbob,456"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $originalCsv
            $json = ConvertFrom-CsvToJson -Path $tempFile
            $jsonFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $jsonFile -Value $json
            { ConvertTo-CsvFromJson -Path $jsonFile } | Should -Not -Throw
        }

        It 'ConvertFrom-CsvToYaml converts CSV to YAML' {
            $csv = "name,value`nalice,123`nbob,456"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $csv
            { ConvertFrom-CsvToYaml -Path $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-YamlToCsv converts YAML to CSV' {
            Get-Command ConvertFrom-YamlToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $yaml = "name: alice`nvalue: 123"
            $tempFile = Join-Path $TestDrive 'test.yaml'
            Set-Content -Path $tempFile -Value $yaml
            { ConvertFrom-YamlToCsv -Path $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-CsvToYaml and ConvertFrom-YamlToCsv roundtrip' {
            Get-Command ConvertFrom-YamlToCsv -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $originalCsv = "name,value`nalice,123`nbob,456"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $originalCsv
            { ConvertFrom-CsvToYaml -Path $tempFile } | Should -Not -Throw
            $yamlFile = $tempFile -replace '\.csv$', '.yaml'
            if (Test-Path $yamlFile) {
                { ConvertFrom-YamlToCsv -Path $yamlFile } | Should -Not -Throw
            }
        }

        It 'ConvertTo-CsvFromJson handles empty arrays' {
            $json = '[]'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $json
            $outputFile = $tempFile -replace '\.json$', '.csv'
            ConvertTo-CsvFromJson -Path $tempFile
            # Should not throw, even if output is minimal
        }
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

