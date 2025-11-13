. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

<#
.SYNOPSIS
    Integration tests for data conversion utilities in the PowerShell profile.

.DESCRIPTION
    This test suite validates the functionality of data conversion functions
    including CSV/JSON/XML conversions and base64 encoding/decoding.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
#>

Describe 'Data Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files-conversion.ps1')
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

        It 'ConvertFrom-CsvToYaml converts CSV to YAML' {
            $csv = "name,value`nalice,123`nbob,456"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $csv
            { ConvertFrom-CsvToYaml -Path $tempFile } | Should -Not -Throw
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
            { ConvertFrom-XmlToJson -Path $tempFile } | Should -Not -Throw
        }

        It 'ConvertFrom-XmlToJson handles complex XML structures' {
            $xml = '<users><user><name>alice</name><age>30</age></user><user><name>bob</name><age>25</age></user></users>'
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value $xml
            { ConvertFrom-XmlToJson -Path $tempFile } | Should -Not -Throw
        }
    }

    Context 'Base64 conversion utilities' {
        It 'ConvertTo-Base64 encodes string to base64' {
            $text = 'Hello World'
            $base64 = ConvertTo-Base64 -InputObject $text
            $base64 | Should -Not -BeNullOrEmpty
            $base64 | Should -Be 'SGVsbG8gV29ybGQ='
        }

        It 'ConvertTo-Base64 handles empty string' {
            $text = ''
            $base64 = ConvertTo-Base64 -InputObject $text
            $base64 | Should -Be ''
        }

        It 'ConvertTo-Base64 handles special characters' {
            $text = 'Test with special chars: !@#$%^&*()'
            $base64 = ConvertTo-Base64 -InputObject $text
            $base64 | Should -Not -BeNullOrEmpty
            # Verify it's valid base64 by decoding back
            $decoded = ConvertFrom-Base64 -InputObject $base64
            $decoded | Should -Be $text
        }

        It 'ConvertFrom-Base64 decodes base64 to string' {
            $base64 = 'SGVsbG8gV29ybGQ='
            $text = ConvertFrom-Base64 -InputObject $base64
            $text | Should -Be 'Hello World'
        }

        It 'ConvertFrom-Base64 handles empty base64 string' {
            $base64 = ''
            $text = ConvertFrom-Base64 -InputObject $base64
            $text | Should -Be ''
        }

        It 'ConvertTo-Base64 and ConvertFrom-Base64 roundtrip' {
            $original = 'Test string with unicode: ñáéíóú'
            $base64 = ConvertTo-Base64 -InputObject $original
            $decoded = ConvertFrom-Base64 -InputObject $base64
            $decoded | Should -Be $original
        }

        It 'ConvertFrom-Base64 handles invalid base64 gracefully' {
            $invalidBase64 = 'invalid base64!'
            { ConvertFrom-Base64 -InputObject $invalidBase64 2>$null } | Should -Not -Throw
        }
    }

    Context 'Data conversion error handling' {
        It 'ConvertFrom-CsvToJson handles invalid CSV gracefully' {
            $invalidCsv = '"unclosed quote,name,value'
            $tempFile = Join-Path $TestDrive 'invalid.csv'
            Set-Content -Path $tempFile -Value $invalidCsv
            { ConvertFrom-CsvToJson -Path $tempFile 2>$null } | Should -Not -Throw
        }

        It 'ConvertTo-CsvFromJson handles invalid JSON gracefully' {
            $invalidJson = '{"invalid": json'
            $tempFile = Join-Path $TestDrive 'invalid.json'
            Set-Content -Path $tempFile -Value $invalidJson
            { ConvertTo-CsvFromJson -Path $tempFile 2>$null } | Should -Not -Throw
        }

        It 'ConvertFrom-XmlToJson handles invalid XML gracefully' {
            $invalidXml = '<root><unclosed><tag></root>'
            $tempFile = Join-Path $TestDrive 'invalid.xml'
            Set-Content -Path $tempFile -Value $invalidXml
            { ConvertFrom-XmlToJson -Path $tempFile 2>$null } | Should -Not -Throw
        }
    }
}
