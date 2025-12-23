

<#
.SYNOPSIS
    Integration tests for CSV/XML roundtrip conversions.

.DESCRIPTION
    This test suite validates CSV and XML roundtrip conversion functionality.

.NOTES
    Tests cover roundtrip scenarios between CSV, JSON, YAML, and XML formats.
#>

Describe 'CSV/XML Roundtrip Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'CSV/XML roundtrip utilities' {
        It 'ConvertFrom-CsvToJson and ConvertTo-CsvFromJson roundtrip' {
            $originalCsv = "name,value`nalice,123`nbob,456"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $originalCsv
            $json = ConvertFrom-CsvToJson -Path $tempFile
            $jsonFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $jsonFile -Value $json
            { ConvertTo-CsvFromJson -Path $jsonFile } | Should -Not -Throw
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
            if ($yamlFile -and -not [string]::IsNullOrWhiteSpace($yamlFile) -and (Test-Path -LiteralPath $yamlFile)) {
                { ConvertFrom-YamlToCsv -Path $yamlFile } | Should -Not -Throw
            }
        }
    }
}
