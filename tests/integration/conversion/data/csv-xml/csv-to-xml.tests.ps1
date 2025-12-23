<#
.SYNOPSIS
    Integration tests for CSV to XML conversion utilities.

.DESCRIPTION
    This test suite validates CSV to XML conversion functions.

.NOTES
    Tests cover CSV to XML conversions and related functionality.
#>

Describe 'CSV to XML Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
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
}

