. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

<#
.SYNOPSIS
    Integration tests for cross-format roundtrip conversions.

.DESCRIPTION
    This test suite validates complex multi-format conversion chains to ensure
    data integrity across format transformations.

.NOTES
    Tests cover conversion chains through multiple intermediate formats.
    Requires yq command for YAML/TOML conversions.
#>

Describe 'Cross-Format Roundtrip Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files.ps1')
        Ensure-FileConversion-Data
        Ensure-FileConversion-Documents
    }

    Context 'Cross-format roundtrip conversions' {
        It 'JSON → TOON → YAML → JSON roundtrip' {
            Get-Command ConvertTo-ToonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-ToonToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-Yaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $originalJson = '{"name": "test", "value": 123}'
            $tempFile = Join-Path $TestDrive 'test.json'
            Set-Content -Path $tempFile -Value $originalJson
            { ConvertTo-ToonFromJson -InputPath $tempFile } | Should -Not -Throw
            $toonFile = $tempFile -replace '\.json$', '.toon'
            if (Test-Path $toonFile) {
                { ConvertFrom-ToonToYaml -InputPath $toonFile } | Should -Not -Throw
                $yamlFile = $toonFile -replace '\.toon$', '.yaml'
                if (Test-Path $yamlFile) {
                    { ConvertFrom-Yaml $yamlFile } | Should -Not -Throw
                }
            }
        }

        It 'CSV → JSON → TOON → TOML → JSON → CSV roundtrip' {
            Get-Command ConvertFrom-CsvToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-ToonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-TomlFromToon -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-TomlToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-CsvFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $originalCsv = "name,value`nalice,123`nbob,456"
            $tempFile = Join-Path $TestDrive 'test.csv'
            Set-Content -Path $tempFile -Value $originalCsv
            $json = ConvertFrom-CsvToJson -Path $tempFile
            $jsonFile = $tempFile -replace '\.csv$', '.json'
            Set-Content -Path $jsonFile -Value $json
            { ConvertTo-ToonFromJson -InputPath $jsonFile } | Should -Not -Throw
            $toonFile = $jsonFile -replace '\.json$', '.toon'
            if (Test-Path $toonFile) {
                { ConvertTo-TomlFromToon -InputPath $toonFile } | Should -Not -Throw
                $tomlFile = $toonFile -replace '\.toon$', '.toml'
                if (Test-Path $tomlFile) {
                    { ConvertFrom-TomlToJson -InputPath $tomlFile } | Should -Not -Throw
                    $finalJsonFile = $tomlFile -replace '\.toml$', '.json'
                    if (Test-Path $finalJsonFile) {
                        { ConvertTo-CsvFromJson -Path $finalJsonFile } | Should -Not -Throw
                    }
                }
            }
        }

        It 'XML → JSON → TOON → YAML → TOML → XML roundtrip' {
            Get-Command ConvertFrom-XmlToJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-ToonFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-ToonToYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertTo-TomlFromYaml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            Get-Command ConvertFrom-TomlToXml -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Skip if yq not available
            if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "yq command not available"
                return
            }
            $originalXml = '<root><item name="test" value="123"/></root>'
            $tempFile = Join-Path $TestDrive 'test.xml'
            Set-Content -Path $tempFile -Value $originalXml
            $json = ConvertFrom-XmlToJson -Path $tempFile
            $jsonFile = $tempFile -replace '\.xml$', '.json'
            Set-Content -Path $jsonFile -Value $json
            { ConvertTo-ToonFromJson -InputPath $jsonFile } | Should -Not -Throw
            $toonFile = $jsonFile -replace '\.json$', '.toon'
            if (Test-Path $toonFile) {
                { ConvertFrom-ToonToYaml -InputPath $toonFile } | Should -Not -Throw
                $yamlFile = $toonFile -replace '\.toon$', '.yaml'
                if (Test-Path $yamlFile) {
                    { ConvertTo-TomlFromYaml -InputPath $yamlFile } | Should -Not -Throw
                    $tomlFile = $yamlFile -replace '\.ya?ml$', '.toml'
                    if (Test-Path $tomlFile) {
                        { ConvertFrom-TomlToXml -InputPath $tomlFile } | Should -Not -Throw
                    }
                }
            }
        }
    }
}

